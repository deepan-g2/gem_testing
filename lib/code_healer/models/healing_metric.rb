class HealingMetric < ActiveRecord::Base
  self.table_name = 'healing_metrics'
  
  validates :request_id, presence: true
  validates :error_type, presence: true
  validates :error_message, presence: true
  validates :class_name, presence: true
  validates :method_name, presence: true
  validates :file_path, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending processing completed failed] }
  
  scope :successful, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :recent, ->(days = 7) { where('created_at > ?', days.days.ago) }
  
  def self.total_healing_attempts
    count
  end
  
  def self.success_rate
    return 0 if count == 0
    (successful.count.to_f / count * 100).round(2)
  end
  
  def self.most_common_errors
    group(:error_type)
      .order('count_all DESC')
      .limit(10)
      .count
  end
  
  def self.healing_by_class
    group(:class_name)
      .order('count_all DESC')
      .limit(10)
      .count
  end
  
  def self.recent_healing_activity(days = 7)
    recent(days)
      .group_by_day(:created_at)
      .count
  end
  
  def self.average_healing_time
    return 0 if count == 0
    where.not(completed_at: nil)
      .average('JULIANDAY(completed_at) - JULIANDAY(created_at)')
      .to_f * 24 * 60 # Convert to minutes
  end
  
  def self.healing_by_method
    group(:method_name)
      .order('count_all DESC')
      .limit(10)
      .count
  end
  
  def self.error_trends(days = 30)
    recent(days)
      .group(:error_type)
      .group_by_day(:created_at)
      .count
  end
  
  # Fix: Replace EXTRACT() with SQLite-compatible date functions
  def self.hourly_healing_distribution
    # SQLite uses strftime() instead of EXTRACT()
    group("strftime('%H', created_at)")
      .order("strftime('%H', created_at)")
      .count
  end
  
  def self.daily_healing_distribution
    group("strftime('%w', created_at)")
      .order("strftime('%w', created_at)")
      .count
  end
  
  def self.monthly_healing_distribution
    group("strftime('%m', created_at)")
      .order("strftime('%m', created_at)")
      .count
  end
  
  def self.healing_effectiveness_by_error_type
    group(:error_type)
      .group(:status)
      .count
  end
  
  def self.top_problematic_files
    group(:file_path)
      .order('count_all DESC')
      .limit(20)
      .count
  end
  
  def healing_duration_minutes
    return nil unless completed_at && created_at
    ((completed_at - created_at) * 24 * 60).round(2)
  end
  
  def success?
    status == 'completed'
  end
  
  def failed?
    status == 'failed'
  end
  
  def processing?
    status == 'processing'
  end
  
  def pending?
    status == 'pending'
  end
end
require 'test_helper'

class HealingMetricTest < ActiveSupport::TestCase
  def setup
    @healing_metric = HealingMetric.new(
      request_id: 'test-123',
      error_type: 'NoMethodError',
      error_message: 'undefined method `foo` for nil:NilClass',
      class_name: 'TestClass',
      method_name: 'test_method',
      file_path: '/path/to/test.rb',
      status: 'pending'
    )
  end
  
  test 'should be valid with valid attributes' do
    assert @healing_metric.valid?
  end
  
  test 'should require request_id' do
    @healing_metric.request_id = nil
    assert_not @healing_metric.valid?
    assert_includes @healing_metric.errors[:request_id], "can't be blank"
  end
  
  test 'should require error_type' do
    @healing_metric.error_type = nil
    assert_not @healing_metric.valid?
    assert_includes @healing_metric.errors[:error_type], "can't be blank"
  end
  
  test 'should require valid status' do
    @healing_metric.status = 'invalid_status'
    assert_not @healing_metric.valid?
    assert_includes @healing_metric.errors[:status], 'is not included in the list'
  end
  
  test 'should calculate success rate correctly' do
    # Clear existing records
    HealingMetric.delete_all
    
    # Create test data
    3.times { |i| create_healing_metric(status: 'completed') }
    2.times { |i| create_healing_metric(status: 'failed') }
    
    assert_equal 60.0, HealingMetric.success_rate
  end
  
  test 'should return zero success rate when no records' do
    HealingMetric.delete_all
    assert_equal 0, HealingMetric.success_rate
  end
  
  test 'should group by hour using SQLite strftime function' do
    # Clear existing records
    HealingMetric.delete_all
    
    # Create test data with different hours
    create_healing_metric(created_at: Time.parse('2023-01-01 10:00:00'))
    create_healing_metric(created_at: Time.parse('2023-01-01 10:30:00'))
    create_healing_metric(created_at: Time.parse('2023-01-01 14:00:00'))
    
    # This should not raise an SQLite syntax error
    assert_nothing_raised do
      distribution = HealingMetric.hourly_healing_distribution
      assert distribution.is_a?(Hash)
      assert distribution['10'] == 2
      assert distribution['14'] == 1
    end
  end
  
  test 'should group by day of week using SQLite strftime function' do
    HealingMetric.delete_all
    
    # Sunday = 0, Monday = 1, etc.
    create_healing_metric(created_at: Time.parse('2023-01-01 10:00:00')) # Sunday
    create_healing_metric(created_at: Time.parse('2023-01-02 10:00:00')) # Monday
    create_healing_metric(created_at: Time.parse('2023-01-02 14:00:00')) # Monday
    
    assert_nothing_raised do
      distribution = HealingMetric.daily_healing_distribution
      assert distribution.is_a?(Hash)
      assert distribution['0'] == 1 # Sunday
      assert distribution['1'] == 2 # Monday
    end
  end
  
  test 'should group by month using SQLite strftime function' do
    HealingMetric.delete_all
    
    create_healing_metric(created_at: Time.parse('2023-01-15 10:00:00'))
    create_healing_metric(created_at: Time.parse('2023-02-15 10:00:00'))
    create_healing_metric(created_at: Time.parse('2023-02-20 10:00:00'))
    
    assert_nothing_raised do
      distribution = HealingMetric.monthly_healing_distribution
      assert distribution.is_a?(Hash)
      assert distribution['01'] == 1 # January
      assert distribution['02'] == 2 # February
    end
  end
  
  test 'should calculate healing duration in minutes' do
    created_time = Time.parse('2023-01-01 10:00:00')
    completed_time = Time.parse('2023-01-01 10:05:30')
    
    healing_metric = create_healing_metric(
      created_at: created_time,
      completed_at: completed_time,
      status: 'completed'
    )
    
    assert_equal 5.5, healing_metric.healing_duration_minutes
  end
  
  test 'should return nil duration when not completed' do
    healing_metric = create_healing_metric(completed_at: nil)
    assert_nil healing_metric.healing_duration_minutes
  end
  
  test 'should identify status correctly' do
    assert create_healing_metric(status: 'completed').success?
    assert create_healing_metric(status: 'failed').failed?
    assert create_healing_metric(status: 'processing').processing?
    assert create_healing_metric(status: 'pending').pending?
  end
  
  test 'should scope recent records' do
    HealingMetric.delete_all
    
    # Old record (8 days ago)
    create_healing_metric(created_at: 8.days.ago)
    
    # Recent records (5 days ago)
    recent1 = create_healing_metric(created_at: 5.days.ago)
    recent2 = create_healing_metric(created_at: 1.day.ago)
    
    recent_records = HealingMetric.recent(7)
    assert_equal 2, recent_records.count
    assert_includes recent_records, recent1
    assert_includes recent_records, recent2
  end
  
  test 'should get most common errors' do
    HealingMetric.delete_all
    
    3.times { create_healing_metric(error_type: 'NoMethodError') }
    2.times { create_healing_metric(error_type: 'TypeError') }
    1.times { create_healing_metric(error_type: 'StandardError') }
    
    common_errors = HealingMetric.most_common_errors
    assert_equal 3, common_errors['NoMethodError']
    assert_equal 2, common_errors['TypeError']
    assert_equal 1, common_errors['StandardError']
  end
  
  test 'should calculate average healing time in minutes' do
    HealingMetric.delete_all
    
    # Create completed records with known durations
    base_time = Time.parse('2023-01-01 10:00:00')
    
    # 5 minute healing
    create_healing_metric(
      created_at: base_time,
      completed_at: base_time + 5.minutes,
      status: 'completed'
    )
    
    # 10 minute healing
    create_healing_metric(
      created_at: base_time,
      completed_at: base_time + 10.minutes,
      status: 'completed'
    )
    
    # Should average to 7.5 minutes
    avg_time = HealingMetric.average_healing_time
    assert_in_delta 7.5, avg_time, 0.1
  end
  
  private
  
  def create_healing_metric(attributes = {})
    default_attributes = {
      request_id: SecureRandom.uuid,
      error_type: 'NoMethodError',
      error_message: 'Test error message',
      class_name: 'TestClass',
      method_name: 'test_method',
      file_path: '/path/to/test.rb',
      status: 'pending'
    }
    
    HealingMetric.create!(default_attributes.merge(attributes))
  end
end
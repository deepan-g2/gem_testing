module CodeHealer
  module Services
    class MetricsCollector
      attr_reader :healing_metric
      
      def initialize(healing_metric = nil)
        @healing_metric = healing_metric
      end
      
      def self.collect_error_metrics(error, context = {})
        metrics = {
          error_type: error.class.name,
          error_message: error.message,
          backtrace: error.backtrace&.first(10)&.join("\n"),
          context: context.to_json,
          occurred_at: Time.current
        }
        
        store_metrics(metrics)
      end
      
      def self.collect_healing_attempt(request_id, error, class_name, method_name, file_path)
        HealingMetric.create!(
          request_id: request_id,
          error_type: error.class.name,
          error_message: error.message,
          class_name: class_name,
          method_name: method_name,
          file_path: file_path,
          status: 'pending',
          created_at: Time.current
        )
      end
      
      def self.mark_healing_started(healing_metric_id)
        healing_metric = HealingMetric.find(healing_metric_id)
        healing_metric.update!(status: 'processing', started_at: Time.current)
      end
      
      def self.mark_healing_completed(healing_metric_id, success: true, details: nil)
        healing_metric = HealingMetric.find(healing_metric_id)
        status = success ? 'completed' : 'failed'
        
        healing_metric.update!(
          status: status,
          completed_at: Time.current,
          healing_details: details&.to_json
        )
      end
      
      def self.system_health_metrics
        {
          total_attempts: HealingMetric.count,
          success_rate: HealingMetric.success_rate,
          avg_healing_time: HealingMetric.average_healing_time,
          recent_activity: HealingMetric.recent_healing_activity(7),
          error_distribution: HealingMetric.most_common_errors
        }
      end
      
      def self.detailed_analytics(days = 30)
        {
          healing_trends: HealingMetric.recent(days).group_by_day(:created_at).count,
          error_types: HealingMetric.recent(days).group(:error_type).count,
          class_distribution: HealingMetric.recent(days).group(:class_name).count,
          method_distribution: HealingMetric.recent(days).group(:method_name).count,
          hourly_pattern: HealingMetric.recent(days).hourly_healing_distribution,
          success_by_error_type: HealingMetric.recent(days).healing_effectiveness_by_error_type
        }
      end
      
      def self.performance_insights
        {
          fastest_healings: HealingMetric.successful
                                        .where.not(completed_at: nil)
                                        .order('(JULIANDAY(completed_at) - JULIANDAY(created_at)) ASC')
                                        .limit(10),
          slowest_healings: HealingMetric.successful
                                        .where.not(completed_at: nil)
                                        .order('(JULIANDAY(completed_at) - JULIANDAY(created_at)) DESC')
                                        .limit(10),
          problematic_files: HealingMetric.top_problematic_files,
          healing_by_hour: HealingMetric.hourly_healing_distribution
        }
      end
      
      def self.dashboard_summary
        recent_metrics = HealingMetric.recent(7)
        
        {
          total_healings: HealingMetric.count,
          recent_healings: recent_metrics.count,
          success_rate: HealingMetric.success_rate,
          recent_success_rate: recent_metrics.count > 0 ? 
            (recent_metrics.successful.count.to_f / recent_metrics.count * 100).round(2) : 0,
          avg_healing_time: HealingMetric.average_healing_time,
          most_common_errors: HealingMetric.most_common_errors.first(5),
          hourly_distribution: HealingMetric.hourly_healing_distribution,
          daily_activity: HealingMetric.recent_healing_activity(7),
          top_classes: HealingMetric.healing_by_class.first(5),
          recent_failures: recent_metrics.failed.limit(10).order(created_at: :desc)
        }
      end
      
      def self.export_metrics(format: :json, date_range: 30.days.ago..Time.current)
        metrics = HealingMetric.where(created_at: date_range)
        
        case format
        when :json
          metrics.as_json(
            include: {
              healing_details: {},
              error_context: {}
            },
            methods: [:healing_duration_minutes, :success?]
          )
        when :csv
          generate_csv_export(metrics)
        else
          raise ArgumentError, "Unsupported format: #{format}"
        end
      end
      
      private
      
      def self.store_metrics(metrics)
        # Store in database or external service
        # This could be extended to support different storage backends
        Rails.logger.info "Healing Metrics: #{metrics.to_json}"
      end
      
      def self.generate_csv_export(metrics)
        require 'csv'
        
        CSV.generate(headers: true) do |csv|
          csv << %w[
            request_id error_type error_message class_name method_name
            file_path status created_at completed_at healing_duration_minutes
          ]
          
          metrics.each do |metric|
            csv << [
              metric.request_id,
              metric.error_type,
              metric.error_message,
              metric.class_name,
              metric.method_name,
              metric.file_path,
              metric.status,
              metric.created_at,
              metric.completed_at,
              metric.healing_duration_minutes
            ]
          end
        end
      end
    end
  end
end
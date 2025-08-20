module CodeHealer
  module Controllers
    class DashboardController < ApplicationController
      def index
        @dashboard_data = CodeHealer::Services::MetricsCollector.dashboard_summary
        
        respond_to do |format|
          format.html { render 'code_healer/dashboard/index' }
          format.json { render json: @dashboard_data }
        end
      rescue StandardError => e
        Rails.logger.error "Error loading dashboard: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        
        @error_message = "Unable to load dashboard data: #{e.message}"
        
        respond_to do |format|
          format.html { render 'code_healer/dashboard/error', status: :internal_server_error }
          format.json { render json: { error: @error_message }, status: :internal_server_error }
        end
      end
      
      def analytics
        days = params[:days]&.to_i || 30
        @analytics_data = CodeHealer::Services::MetricsCollector.detailed_analytics(days)
        
        respond_to do |format|
          format.html { render 'code_healer/dashboard/analytics' }
          format.json { render json: @analytics_data }
        end
      rescue StandardError => e
        Rails.logger.error "Error loading analytics: #{e.message}"
        
        respond_to do |format|
          format.html { render 'code_healer/dashboard/error', status: :internal_server_error }
          format.json { render json: { error: e.message }, status: :internal_server_error }
        end
      end
      
      def export
        format = params[:format]&.to_sym || :json
        date_range = parse_date_range
        
        exported_data = CodeHealer::Services::MetricsCollector.export_metrics(
          format: format, 
          date_range: date_range
        )
        
        respond_to do |format|
          format.json { render json: exported_data }
          format.csv do
            send_data exported_data, 
                     filename: "healing_metrics_#{Date.current}.csv",
                     type: 'text/csv'
          end
        end
      rescue StandardError => e
        Rails.logger.error "Error exporting metrics: #{e.message}"
        render json: { error: e.message }, status: :internal_server_error
      end
      
      private
      
      def parse_date_range
        start_date = params[:start_date] ? Date.parse(params[:start_date]) : 30.days.ago
        end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.current
        start_date.beginning_of_day..end_date.end_of_day
      rescue Date::Error
        30.days.ago.beginning_of_day..Time.current
      end
    end
  end
end
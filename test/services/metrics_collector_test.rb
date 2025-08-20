require 'test_helper'

class MetricsCollectorTest < ActiveSupport::TestCase
  def setup
    HealingMetric.delete_all
  end
  
  test 'should collect healing attempt' do
    error = StandardError.new('Test error')
    request_id = 'test-123'
    
    assert_difference 'HealingMetric.count', 1 do
      healing_metric = CodeHealer::Services::MetricsCollector.collect_healing_attempt(
        request_id,
        error,
        'TestClass',
        'test_method',
        '/path/to/test.rb'
      )
      
      assert_equal request_id, healing_metric.request_id
      assert_equal 'StandardError', healing_metric.error_type
      assert_equal 'Test error', healing_metric.error_message
      assert_equal 'TestClass', healing_metric.class_name
      assert_equal 'test_method', healing_metric.method_name
      assert_equal '/path/to/test.rb', healing_metric.file_path
      assert_equal 'pending', healing_metric.status
    end
  end
  
  test 'should mark healing as started' do
    healing_metric = create_healing_metric
    
    CodeHealer::Services::MetricsCollector.mark_healing_started(healing_metric.id)
    
    healing_metric.reload
    assert_equal 'processing', healing_metric.status
    assert_not_nil healing_metric.started_at
  end
  
  test 'should mark healing as completed successfully' do
    healing_metric = create_healing_metric(status: 'processing')
    details = { fixed_method: 'test_method', changes_made: 2 }
    
    CodeHealer::Services::MetricsCollector.mark_healing_completed(
      healing_metric.id,
      success: true,
      details: details
    )
    
    healing_metric.reload
    assert_equal 'completed', healing_metric.status
    assert_not_nil healing_metric.completed_at
    assert_equal details.to_json, healing_metric.healing_details
  end
  
  test 'should mark healing as failed' do
    healing_metric = create_healing_metric(status: 'processing')
    details = { error: 'Could not fix', reason: 'Syntax error' }
    
    CodeHealer::Services::MetricsCollector.mark_healing_completed(
      healing_metric.id,
      success: false,
      details: details
    )
    
    healing_metric.reload
    assert_equal 'failed', healing_metric.status
    assert_not_nil healing_metric.completed_at
    assert_equal details.to_json, healing_metric.healing_details
  end
  
  test 'should generate system health metrics' do
    # Create test data
    3.times { create_healing_metric(status: 'completed') }
    2.times { create_healing_metric(status: 'failed') }
    1.times { create_healing_metric(status: 'pending') }
    
    health_metrics = CodeHealer::Services::MetricsCollector.system_health_metrics
    
    assert_equal 6, health_metrics[:total_attempts]
    assert_equal 50.0, health_metrics[:success_rate]
    assert health_metrics.key?(:avg_healing_time)
    assert health_metrics.key?(:recent_activity)
    assert health_metrics.key?(:error_distribution)
  end
  
  test 'should generate detailed analytics without SQLite errors' do
    # Create test data with different timestamps
    create_healing_metric(
      error_type: 'NoMethodError',
      created_at: 2.days.ago,
      status: 'completed'
    )
    create_healing_metric(
      error_type: 'TypeError',
      created_at: 1.day.ago,
      status: 'failed'
    )
    
    # This should not raise SQLite EXTRACT() errors
    assert_nothing_raised do
      analytics = CodeHealer::Services::MetricsCollector.detailed_analytics(7)
      
      assert analytics.key?(:healing_trends)
      assert analytics.key?(:error_types)
      assert analytics.key?(:class_distribution)
      assert analytics.key?(:method_distribution)
      assert analytics.key?(:hourly_pattern)
      assert analytics.key?(:success_by_error_type)
      
      # Verify hourly_pattern specifically (this was causing the SQLite error)
      assert analytics[:hourly_pattern].is_a?(Hash)
    end
  end
  
  test 'should generate performance insights' do
    # Create completed healings with different durations
    base_time = 1.hour.ago
    
    fast_healing = create_healing_metric(
      status: 'completed',
      created_at: base_time,
      completed_at: base_time + 1.minute
    )
    
    slow_healing = create_healing_metric(
      status: 'completed',
      created_at: base_time,
      completed_at: base_time + 10.minutes
    )
    
    assert_nothing_raised do
      insights = CodeHealer::Services::MetricsCollector.performance_insights
      
      assert insights.key?(:fastest_healings)
      assert insights.key?(:slowest_healings)
      assert insights.key?(:problematic_files)
      assert insights.key?(:healing_by_hour)
      
      # Verify healing_by_hour specifically
      assert insights[:healing_by_hour].is_a?(Hash)
    end
  end
  
  test 'should generate dashboard summary without errors' do
    # Create diverse test data
    create_healing_metric(
      error_type: 'NoMethodError',
      class_name: 'UserModel',
      created_at: 2.days.ago,
      status: 'completed'
    )
    
    create_healing_metric(
      error_type: 'TypeError',
      class_name: 'OrderProcessor',
      created_at: 1.day.ago,
      status: 'failed'
    )
    
    # This method calls hourly_healing_distribution which was causing the error
    assert_nothing_raised do
      summary = CodeHealer::Services::MetricsCollector.dashboard_summary
      
      assert summary.key?(:total_healings)
      assert summary.key?(:recent_healings)
      assert summary.key?(:success_rate)
      assert summary.key?(:recent_success_rate)
      assert summary.key?(:avg_healing_time)
      assert summary.key?(:most_common_errors)
      assert summary.key?(:hourly_distribution)
      assert summary.key?(:daily_activity)
      assert summary.key?(:top_classes)
      assert summary.key?(:recent_failures)
      
      # Verify the problematic hourly_distribution
      assert summary[:hourly_distribution].is_a?(Hash)
    end
  end
  
  test 'should export metrics as JSON' do
    healing_metric = create_healing_metric(
      status: 'completed',
      completed_at: Time.current
    )
    
    exported_data = CodeHealer::Services::MetricsCollector.export_metrics(
      format: :json,
      date_range: 1.day.ago..Time.current
    )
    
    assert exported_data.is_a?(Array)
    assert_equal 1, exported_data.length
    
    exported_record = exported_data.first
    assert_equal healing_metric.request_id, exported_record['request_id']
    assert_equal 'completed', exported_record['status']
    assert exported_record.key?('healing_duration_minutes')
    assert exported_record.key?('success?')
  end
  
  test 'should export metrics as CSV' do
    create_healing_metric(
      status: 'completed',
      completed_at: Time.current
    )
    
    csv_data = CodeHealer::Services::MetricsCollector.export_metrics(
      format: :csv,
      date_range: 1.day.ago..Time.current
    )
    
    assert csv_data.is_a?(String)
    assert csv_data.include?('request_id,error_type,error_message')
    assert csv_data.include?('completed')
  end
  
  test 'should raise error for unsupported export format' do
    assert_raises ArgumentError do
      CodeHealer::Services::MetricsCollector.export_metrics(format: :xml)
    end
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
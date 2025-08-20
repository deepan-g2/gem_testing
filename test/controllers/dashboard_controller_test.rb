require 'test_helper'

class DashboardControllerTest < ActionDispatch::IntegrationTest
  def setup
    HealingMetric.delete_all
    @base_url = '/code_healer/dashboard'
  end
  
  test 'should get dashboard index without SQLite errors' do
    # Create test data that would trigger the SQLite EXTRACT() error
    create_healing_metric(
      error_type: 'NoMethodError',
      created_at: Time.parse('2023-01-01 10:30:00'),
      status: 'completed'
    )
    
    create_healing_metric(
      error_type: 'TypeError',
      created_at: Time.parse('2023-01-01 14:15:00'),
      status: 'failed'
    )
    
    # This request should not raise SQLite syntax errors
    assert_nothing_raised do
      get @base_url
    end
    
    assert_response :success
  end
  
  test 'should get dashboard index as JSON' do
    create_healing_metric(status: 'completed')
    create_healing_metric(status: 'failed')
    
    get @base_url, headers: { 'Accept' => 'application/json' }
    
    assert_response :success
    assert_equal 'application/json', response.content_type.split(';').first
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('total_healings')
    assert json_response.key?('success_rate')
    assert json_response.key?('hourly_distribution')
    
    # Verify the hourly_distribution that was causing errors
    assert json_response['hourly_distribution'].is_a?(Hash)
  end
  
  test 'should handle dashboard errors gracefully' do
    # Mock an error in the MetricsCollector
    CodeHealer::Services::MetricsCollector.stub(:dashboard_summary, -> { raise StandardError, 'Test error' }) do
      get @base_url
      
      assert_response :internal_server_error
    end
  end
  
  test 'should handle dashboard JSON errors gracefully' do
    CodeHealer::Services::MetricsCollector.stub(:dashboard_summary, -> { raise StandardError, 'Test error' }) do
      get @base_url, headers: { 'Accept' => 'application/json' }
      
      assert_response :internal_server_error
      assert_equal 'application/json', response.content_type.split(';').first
      
      json_response = JSON.parse(response.body)
      assert json_response.key?('error')
      assert_includes json_response['error'], 'Test error'
    end
  end
  
  test 'should get analytics page' do
    create_healing_metric(created_at: 5.days.ago, status: 'completed')
    create_healing_metric(created_at: 2.days.ago, status: 'failed')
    
    get "#{@base_url}/analytics"
    
    assert_response :success
  end
  
  test 'should get analytics with custom days parameter' do
    create_healing_metric(created_at: 15.days.ago, status: 'completed')
    
    get "#{@base_url}/analytics", params: { days: 30 }
    
    assert_response :success
  end
  
  test 'should get analytics as JSON' do
    create_healing_metric(
      created_at: 2.days.ago,
      status: 'completed'
    )
    
    get "#{@base_url}/analytics", headers: { 'Accept' => 'application/json' }
    
    assert_response :success
    assert_equal 'application/json', response.content_type.split(';').first
    
    json_response = JSON.parse(response.body)
    assert json_response.key?('healing_trends')
    assert json_response.key?('hourly_pattern')
    
    # Verify hourly_pattern doesn't cause SQLite errors
    assert json_response['hourly_pattern'].is_a?(Hash)
  end
  
  test 'should handle analytics errors gracefully' do
    CodeHealer::Services::MetricsCollector.stub(:detailed_analytics, -> { raise StandardError, 'Analytics error' }) do
      get "#{@base_url}/analytics"
      
      assert_response :internal_server_error
    end
  end
  
  test 'should export metrics as JSON' do
    healing_metric = create_healing_metric(
      status: 'completed',
      completed_at: Time.current
    )
    
    get "#{@base_url}/export", params: { format: 'json' }
    
    assert_response :success
    assert_equal 'application/json', response.content_type.split(';').first
    
    json_response = JSON.parse(response.body)
    assert json_response.is_a?(Array)
    assert_equal 1, json_response.length
  end
  
  test 'should export metrics as CSV' do
    create_healing_metric(
      status: 'completed',
      completed_at: Time.current
    )
    
    get "#{@base_url}/export", params: { format: 'csv' }
    
    assert_response :success
    assert_equal 'text/csv', response.content_type
    assert response.body.include?('request_id,error_type')
  end
  
  test 'should handle export date range parameters' do
    # Create metrics outside and inside date range
    create_healing_metric(created_at: 10.days.ago, status: 'completed')
    create_healing_metric(created_at: 2.days.ago, status: 'completed')
    
    start_date = 5.days.ago.to_date.to_s
    end_date = Date.current.to_s
    
    get "#{@base_url}/export", params: { 
      format: 'json',
      start_date: start_date,
      end_date: end_date
    }
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    # Should only include the record from 2 days ago
    assert_equal 1, json_response.length
  end
  
  test 'should handle invalid date range gracefully' do
    create_healing_metric(status: 'completed')
    
    get "#{@base_url}/export", params: { 
      format: 'json',
      start_date: 'invalid-date',
      end_date: 'also-invalid'
    }
    
    # Should still work with default date range
    assert_response :success
  end
  
  test 'should handle export errors gracefully' do
    CodeHealer::Services::MetricsCollector.stub(:export_metrics, -> { raise StandardError, 'Export error' }) do
      get "#{@base_url}/export", params: { format: 'json' }
      
      assert_response :internal_server_error
      
      json_response = JSON.parse(response.body)
      assert json_response.key?('error')
      assert_includes json_response['error'], 'Export error'
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
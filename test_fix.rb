#!/usr/bin/env ruby

# Simple test runner to verify SQLite compatibility fix
require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  
  gem 'sqlite3', '~> 2.7'
  gem 'activerecord', '~> 7.1'
  gem 'activesupport', '~> 7.1'
end

require 'active_record'
require 'sqlite3'

# Setup in-memory SQLite database for testing
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# Load our model
require_relative 'lib/code_healer/models/healing_metric'

# Create the table
ActiveRecord::Schema.define do
  create_table :healing_metrics do |t|
    t.string :request_id, null: false
    t.string :error_type, null: false
    t.text :error_message, null: false
    t.string :class_name, null: false
    t.string :method_name, null: false
    t.string :file_path, null: false
    t.string :status, null: false, default: 'pending'
    t.datetime :started_at
    t.datetime :completed_at
    t.text :healing_details
    t.text :error_context
    t.text :backtrace
    
    t.timestamps
  end
end

# Test data
puts "Creating test data..."

test_records = [
  {
    request_id: 'test-001',
    error_type: 'NoMethodError',
    error_message: 'undefined method `foo` for nil:NilClass',
    class_name: 'UserModel',
    method_name: 'process_user',
    file_path: '/app/models/user.rb',
    status: 'completed',
    created_at: Time.parse('2023-12-15 10:30:00'),
    completed_at: Time.parse('2023-12-15 10:35:00')
  },
  {
    request_id: 'test-002', 
    error_type: 'TypeError',
    error_message: 'no implicit conversion of String into Integer',
    class_name: 'OrderProcessor',
    method_name: 'calculate_total',
    file_path: '/app/services/order_processor.rb',
    status: 'failed',
    created_at: Time.parse('2023-12-15 14:15:00')
  },
  {
    request_id: 'test-003',
    error_type: 'NoMethodError',
    error_message: 'undefined method `bar` for Object',
    class_name: 'PaymentService',
    method_name: 'process_payment',
    file_path: '/app/services/payment_service.rb',
    status: 'completed',
    created_at: Time.parse('2023-12-15 16:45:00'),
    completed_at: Time.parse('2023-12-15 16:50:00')
  }
]

test_records.each { |record| HealingMetric.create!(record) }

puts "Test data created: #{HealingMetric.count} records"
puts

# Test the problematic method that was causing SQLite errors
puts "Testing hourly_healing_distribution (this was causing SQLite EXTRACT() errors)..."

begin
  distribution = HealingMetric.hourly_healing_distribution
  puts "✅ SUCCESS: hourly_healing_distribution works!"
  puts "Results: #{distribution}"
rescue => e
  puts "❌ FAILED: #{e.message}"
  puts "Backtrace: #{e.backtrace.first(3).join("\n")}"
end

puts

# Test other time-based distributions
puts "Testing other time-based methods..."

test_methods = [
  :daily_healing_distribution,
  :monthly_healing_distribution,
  :success_rate,
  :average_healing_time,
  :most_common_errors,
  :healing_by_class
]

test_methods.each do |method|
  begin
    result = HealingMetric.send(method)
    puts "✅ #{method}: #{result.is_a?(Hash) ? result.keys.length : result} #{result.is_a?(Hash) ? 'entries' : ''}"
  rescue => e
    puts "❌ #{method} FAILED: #{e.message}"
  end
end

puts
puts "Testing MetricsCollector dashboard_summary (this was the original failing method)..."

# Load the service
require_relative 'lib/code_healer/services/metrics_collector'

begin
  summary = CodeHealer::Services::MetricsCollector.dashboard_summary
  puts "✅ SUCCESS: dashboard_summary works!"
  puts "Summary keys: #{summary.keys}"
  puts "Hourly distribution: #{summary[:hourly_distribution]}"
rescue => e
  puts "❌ FAILED: #{e.message}"
  puts "Backtrace: #{e.backtrace.first(5).join("\n")}"
end

puts
puts "=== SQLite Compatibility Fix Test Complete ==="
puts

# Show the fixed SQL query
puts "The original failing query was:"
puts "SELECT COUNT(*) AS \"count_all\", EXTRACT(HOUR FROM created_at) AS \"extract_hour_from_created_at\" FROM \"healing_metrics\" GROUP BY EXTRACT(HOUR FROM created_at) ORDER BY EXTRACT(HOUR FROM created_at)"
puts
puts "Fixed query uses SQLite-compatible strftime() function:"
puts "SELECT COUNT(*) AS \"count_all\", strftime('%H', created_at) AS \"strftime_h_created_at\" FROM \"healing_metrics\" GROUP BY strftime('%H', created_at) ORDER BY strftime('%H', created_at)"
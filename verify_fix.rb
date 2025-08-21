#!/usr/bin/env ruby

# Comprehensive verification script to test OrderProcessor fixes for TypeError
require_relative 'app/models/order_processor'

# Mock Rails.logger if not available
module Rails
  def self.logger
    @logger ||= Class.new do
      def error(message); puts "LOG: #{message}"; end
    end.new
  end
end unless defined?(Rails)

def run_verification_tests
  processor = OrderProcessor.new
  
  puts "🔍 Testing OrderProcessor fixes for TypeError: 'nil can't be coerced into Integer'"
  puts "=" * 80
  
  test_results = []
  
  # Test cases that specifically address the original TypeError
  test_cases = [
    {
      name: "nil items array",
      items: nil,
      expected: 0.0,
      description: "Should handle nil input without crashing"
    },
    {
      name: "empty items array", 
      items: [],
      expected: 0.0,
      description: "Should handle empty array"
    },
    {
      name: "items with nil price", 
      items: [{ price: nil, quantity: 2 }, { price: 10.0, quantity: 2 }],
      expected: 20.0,
      description: "Should skip items with nil price (original error trigger)"
    },
    {
      name: "items with nil quantity",
      items: [{ price: 10.0, quantity: nil }, { price: 5.0, quantity: 3 }],
      expected: 15.0,
      description: "Should skip items with nil quantity"
    },
    {
      name: "items with both nil price and quantity",
      items: [{ price: nil, quantity: nil }, { price: 8.0, quantity: 2 }],
      expected: 16.0,
      description: "Should skip items where both are nil"
    },
    {
      name: "items with infinity values",
      items: [{ price: Float::INFINITY, quantity: 2 }, { price: 7.0, quantity: 2 }],
      expected: 14.0,
      description: "Should handle infinity values without error"
    },
    {
      name: "items with NaN values",
      items: [{ price: Float::NAN, quantity: 3 }, { price: 6.0, quantity: 2 }],
      expected: 12.0,
      description: "Should handle NaN values without error"
    },
    {
      name: "items with invalid string values",
      items: [{ price: "invalid", quantity: "also_invalid" }, { price: 9.0, quantity: 2 }],
      expected: 18.0,
      description: "Should handle invalid strings gracefully"
    },
    {
      name: "items with empty strings",
      items: [{ price: "", quantity: "" }, { price: 4.0, quantity: 3 }],
      expected: 12.0,
      description: "Should handle empty strings"
    },
    {
      name: "items with non-numeric types",
      items: [{ price: [], quantity: {} }, { price: true, quantity: false }, { price: 5.0, quantity: 2 }],
      expected: 10.0,
      description: "Should handle arrays, hashes, booleans"
    },
    {
      name: "all invalid items",
      items: [{ price: nil, quantity: nil }, { price: "invalid", quantity: "invalid" }],
      expected: 0.0,
      description: "Should return 0 when all items are invalid"
    },
    {
      name: "overflow scenario",
      items: [{ price: 1e100, quantity: 1e100 }, { price: 3.0, quantity: 4.0 }],
      expected: 12.0,
      description: "Should handle potential overflow cases"
    }
  ]
  
  # Run each test
  test_cases.each_with_index do |test_case, index|
    begin
      result = processor.calculate_total(test_case[:items])
      
      # Check for nil result (the original error)
      if result.nil?
        test_results << {
          name: test_case[:name],
          status: "❌ FAIL",
          error: "Method returned nil!",
          description: test_case[:description]
        }
        next
      end
      
      # Check if result is a valid finite number
      unless result.is_a?(Numeric) && result.finite?
        test_results << {
          name: test_case[:name],
          status: "❌ FAIL", 
          error: "Result is not a finite number: #{result}",
          description: test_case[:description]
        }
        next
      end
      
      # Check expected value
      if (result - test_case[:expected]).abs < 0.001  # Float comparison with tolerance
        test_results << {
          name: test_case[:name],
          status: "✅ PASS",
          result: result,
          expected: test_case[:expected],
          description: test_case[:description]
        }
      else
        test_results << {
          name: test_case[:name],
          status: "❌ FAIL",
          error: "Expected #{test_case[:expected]}, got #{result}",
          description: test_case[:description]
        }
      end
      
    rescue => e
      test_results << {
        name: test_case[:name],
        status: "❌ ERROR",
        error: "#{e.class}: #{e.message}",
        description: test_case[:description]
      }
    end
  end
  
  # Display results
  test_results.each do |result|
    puts "#{result[:status]} #{result[:name]}"
    puts "   📝 #{result[:description]}"
    if result[:error]
      puts "   ⚠️  #{result[:error]}"
    elsif result[:result]
      puts "   ✓ Result: #{result[:result]} (expected: #{result[:expected]})"
    end
    puts
  end
  
  # Summary
  passed = test_results.count { |r| r[:status].include?("PASS") }
  total = test_results.length
  
  puts "=" * 80
  puts "📊 SUMMARY: #{passed}/#{total} tests passed"
  
  if passed == total
    puts "🎉 SUCCESS! All tests passed. The TypeError fix is working correctly."
    puts "   The error 'nil can't be coerced into Integer' has been resolved."
  else
    puts "❌ FAILURE: #{total - passed} tests failed. Please review the implementation."
  end
  
  puts "=" * 80
  
  # Test convert_to_number method specifically
  puts "\n🔍 Testing convert_to_number method (root cause of TypeError)..."
  puts "-" * 50
  
  convert_tests = [
    [nil, 0.0, "nil input"],
    [42, 42.0, "integer input"],
    [42.5, 42.5, "float input"],
    [Float::INFINITY, 0.0, "infinity input"],
    [Float::NAN, 0.0, "NaN input"],
    ["10.50", 10.50, "valid string"],
    ["invalid", 0.0, "invalid string"],
    ["", 0.0, "empty string"],
    [[], 0.0, "array input"],
    [{}, 0.0, "hash input"]
  ]
  
  convert_passed = 0
  convert_tests.each do |input, expected, desc|
    begin
      result = processor.convert_to_number(input)
      
      if result.nil?
        puts "❌ #{desc}: Returned nil!"
      elsif !result.is_a?(Numeric) || !result.finite?
        puts "❌ #{desc}: Not finite numeric: #{result}"
      elsif (result - expected).abs < 0.001
        puts "✅ #{desc}: #{result}"
        convert_passed += 1
      else
        puts "❌ #{desc}: Expected #{expected}, got #{result}"
      end
    rescue => e
      puts "❌ #{desc}: Exception: #{e.class} - #{e.message}"
    end
  end
  
  puts "-" * 50
  puts "convert_to_number: #{convert_passed}/#{convert_tests.length} tests passed"
  
  return passed == total && convert_passed == convert_tests.length
end

# Run the verification
success = run_verification_tests

if success
  puts "\n🏆 FINAL RESULT: All fixes are working correctly!"
  puts "   The TypeError 'nil can't be coerced into Integer' is fully resolved."
else
  puts "\n🚨 FINAL RESULT: Some issues remain. Please review the implementation."
end
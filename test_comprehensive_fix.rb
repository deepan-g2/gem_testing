#!/usr/bin/env ruby

# Comprehensive test to verify the OrderProcessor fix
# This script tests all edge cases that could cause "nil can't be coerced into Integer" error

require_relative 'app/models/order_processor'

def test_case(description, items)
  puts "\n=== #{description} ==="
  puts "Items: #{items.inspect}"
  
  begin
    processor = OrderProcessor.new
    result = processor.calculate_total(items)
    puts "✅ SUCCESS: #{result}"
    puts "✅ Result is numeric: #{result.is_a?(Numeric)}"
    puts "✅ Result is finite: #{result.finite? rescue false}"
    return true
  rescue => e
    puts "❌ ERROR: #{e.class} - #{e.message}"
    puts "❌ Backtrace: #{e.backtrace.first(3).join(' | ')}"
    return false
  end
end

puts "🔍 COMPREHENSIVE FIX VERIFICATION"
puts "=" * 50

# Test cases that could cause the original error
test_cases = [
  ["Empty array", []],
  ["Nil input", nil],
  ["Single item with nils", [{ price: nil, quantity: nil }]],
  ["Mixed valid and nil items", [
    { price: 10.50, quantity: 2 },
    { price: nil, quantity: nil },
    { price: 5.25, quantity: 3 }
  ]],
  ["All nil items", [
    { price: nil, quantity: nil },
    { price: nil, quantity: nil }
  ]],
  ["Missing keys", [
    { price: 10.50 },
    { quantity: 2 },
    {}
  ]],
  ["Zero and negative values", [
    { price: 0, quantity: 2 },
    { price: -5, quantity: 1 },
    { price: 10.50, quantity: 0 },
    { price: 15.75, quantity: -1 }
  ]],
  ["String values", [
    { price: "10.50", quantity: "2" },
    { price: "$5.25", quantity: "3" },
    { price: "invalid", quantity: "also_invalid" }
  ]],
  ["Edge case numeric values", [
    { price: Float::INFINITY, quantity: 2 },
    { price: Float::NAN, quantity: 3 },
    { price: -Float::INFINITY, quantity: 1 }
  ]],
  ["Complex mixed scenario", [
    nil,
    { price: nil, quantity: nil },
    { price: "invalid", quantity: "bad" },
    { price: 0, quantity: 2 },
    { price: -5, quantity: -1 },
    { price: Float::NAN, quantity: Float::INFINITY },
    { price: "10.50", quantity: "2" },
    { price: "$5.25", quantity: "3" }
  ]]
]

success_count = 0
total_count = test_cases.length

test_cases.each do |description, items|
  success_count += 1 if test_case(description, items)
end

puts "\n" + "=" * 50
puts "🎯 SUMMARY"
puts "Passed: #{success_count}/#{total_count}"

if success_count == total_count
  puts "✅ ALL TESTS PASSED - Fix is working correctly!"
  puts "✅ The TypeError 'nil can't be coerced into Integer' should be resolved."
else
  puts "❌ SOME TESTS FAILED - Fix needs more work."
end

puts "\n🔧 ADDITIONAL VERIFICATION"
puts "Testing convert_to_number method directly:"

test_values = [nil, "", "invalid", Float::INFINITY, Float::NAN, [], {}, true, false]
processor = OrderProcessor.new

test_values.each do |value|
  result = processor.convert_to_number(value)
  puts "  #{value.inspect} -> #{result} (#{result.class})"
end

puts "\n🚀 Fix verification complete!"
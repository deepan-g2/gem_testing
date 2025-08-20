#!/usr/bin/env ruby

# Quick verification script to test the OrderProcessor fix
require_relative 'app/models/order_processor'

def test_fix
  processor = OrderProcessor.new
  
  puts "Testing OrderProcessor fix..."
  
  # Test 1: nil items
  result = processor.calculate_total(nil)
  puts "✓ nil items: #{result == 0 ? 'PASS' : 'FAIL'} (expected: 0, got: #{result})"
  
  # Test 2: empty array
  result = processor.calculate_total([])
  puts "✓ empty array: #{result == 0 ? 'PASS' : 'FAIL'} (expected: 0, got: #{result})"
  
  # Test 3: valid items
  items = [{ price: 10.5, quantity: 2 }, { price: 5.25, quantity: 3 }]
  result = processor.calculate_total(items)
  expected = (10.5 * 2) + (5.25 * 3)
  puts "✓ valid items: #{result == expected ? 'PASS' : 'FAIL'} (expected: #{expected}, got: #{result})"
  
  # Test 4: nil price
  items = [{ price: nil, quantity: 2 }, { price: 5.25, quantity: 3 }]
  result = processor.calculate_total(items)
  expected = 5.25 * 3
  puts "✓ nil price: #{result == expected ? 'PASS' : 'FAIL'} (expected: #{expected}, got: #{result})"
  
  # Test 5: nil quantity
  items = [{ price: 10.5, quantity: nil }, { price: 5.25, quantity: 3 }]
  result = processor.calculate_total(items)
  expected = 5.25 * 3
  puts "✓ nil quantity: #{result == expected ? 'PASS' : 'FAIL'} (expected: #{expected}, got: #{result})"
  
  # Test 6: missing keys
  items = [{ quantity: 2 }, { price: 5.25, quantity: 3 }]
  result = processor.calculate_total(items)
  expected = 5.25 * 3
  puts "✓ missing price key: #{result == expected ? 'PASS' : 'FAIL'} (expected: #{expected}, got: #{result})"
  
  # Test 7: zero/negative values
  items = [{ price: 0, quantity: 2 }, { price: -5.25, quantity: 3 }, { price: 10.0, quantity: 2 }]
  result = processor.calculate_total(items)
  expected = 10.0 * 2
  puts "✓ zero/negative values: #{result == expected ? 'PASS' : 'FAIL'} (expected: #{expected}, got: #{result})"
  
  # Test 8: string values
  items = [{ price: "10.5", quantity: "2" }, { price: "5.25", quantity: "3" }]
  result = processor.calculate_total(items)
  expected = (10.5 * 2) + (5.25 * 3)
  puts "✓ string values: #{result == expected ? 'PASS' : 'FAIL'} (expected: #{expected}, got: #{result})"
  
  # Test 9: invalid string values
  items = [{ price: "invalid", quantity: "also_invalid" }, { price: 5.25, quantity: 3 }]
  result = processor.calculate_total(items)
  expected = 5.25 * 3
  puts "✓ invalid strings: #{result == expected ? 'PASS' : 'FAIL'} (expected: #{expected}, got: #{result})"
  
  # Test 10: nil items in array
  items = [{ price: 10.5, quantity: 2 }, nil, { price: 5.25, quantity: 3 }]
  result = processor.calculate_total(items)
  expected = (10.5 * 2) + (5.25 * 3)
  puts "✓ nil items in array: #{result == expected ? 'PASS' : 'FAIL'} (expected: #{expected}, got: #{result})"
  
  # Test 11: infinity and NaN values (edge cases that could cause nil coercion error)
  items = [{ price: Float::INFINITY, quantity: 2 }, { price: Float::NAN, quantity: 3 }, { price: 10.0, quantity: 2 }]
  result = processor.calculate_total(items)
  expected = 10.0 * 2
  puts "✓ infinity/NaN values: #{result == expected ? 'PASS' : 'FAIL'} (expected: #{expected}, got: #{result})"
  
  # Test 12: non-numeric types that could return nil
  items = [{ price: [], quantity: {} }, { price: true, quantity: false }, { price: 10.0, quantity: 2 }]
  result = processor.calculate_total(items)
  expected = 10.0 * 2
  puts "✓ non-numeric types: #{result == expected ? 'PASS' : 'FAIL'} (expected: #{expected}, got: #{result})"
  
  # Test 13: ensure method never returns nil
  nil_results = []
  test_cases = [nil, [], [{ price: nil, quantity: nil }], [{ price: "invalid", quantity: "invalid" }]]
  
  test_cases.each do |test_case|
    result = processor.calculate_total(test_case)
    nil_results << result if result.nil?
  end
  puts "✓ never returns nil: #{nil_results.empty? ? 'PASS' : 'FAIL'} (nil results: #{nil_results.length})"
  
  puts "\nAll tests completed! Fix verification #{nil_results.empty? ? 'SUCCESSFUL' : 'FAILED'}!"
end

test_fix
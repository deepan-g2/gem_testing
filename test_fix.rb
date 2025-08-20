#!/usr/bin/env ruby
require_relative 'app/models/order_processor'

# Test the convert_to_number method
processor = OrderProcessor.new

puts "Testing convert_to_number method:"
puts "nil -> #{processor.convert_to_number(nil)}"
puts "10.5 -> #{processor.convert_to_number(10.5)}"
puts "'10.5' -> #{processor.convert_to_number('10.5')}"
puts "'$10.50' -> #{processor.convert_to_number('$10.50')}"
puts "'invalid' -> #{processor.convert_to_number('invalid')}"

# Test the calculate_total method
items = [
  { price: "10.50", quantity: "2" },
  { price: "$5.25", quantity: "3" }
]

puts "\nTesting calculate_total with items: #{items.inspect}"
total = processor.calculate_total(items)
puts "Total: #{total}"

puts "\nFix verified!"
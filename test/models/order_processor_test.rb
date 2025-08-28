require 'test_helper'

class OrderProcessorTest < ActiveSupport::TestCase
  def setup
    @processor = OrderProcessor.new
  end

  test "calculate_total handles nil items" do
    assert_equal 0, @processor.calculate_total(nil)
  end

  test "calculate_total handles empty array" do
    assert_equal 0, @processor.calculate_total([])
  end

  test "calculate_total handles valid items" do
    items = [
      { price: 10.50, quantity: 2 },
      { price: 5.25, quantity: 3 }
    ]
    expected = (10.50 * 2) + (5.25 * 3)
    assert_equal expected, @processor.calculate_total(items)
  end

  test "calculate_total handles nil items in array" do
    items = [
      { price: 10.50, quantity: 2 },
      nil,
      { price: 5.25, quantity: 3 }
    ]
    expected = (10.50 * 2) + (5.25 * 3)
    assert_equal expected, @processor.calculate_total(items)
  end

  test "calculate_total handles nil price" do
    items = [
      { price: nil, quantity: 2 },
      { price: 5.25, quantity: 3 }
    ]
    expected = 5.25 * 3
    assert_equal expected, @processor.calculate_total(items)
  end

  test "calculate_total handles nil quantity" do
    items = [
      { price: 10.50, quantity: nil },
      { price: 5.25, quantity: 3 }
    ]
    expected = 5.25 * 3
    assert_equal expected, @processor.calculate_total(items)
  end

  test "calculate_total handles missing price key" do
    items = [
      { quantity: 2 },
      { price: 5.25, quantity: 3 }
    ]
    expected = 5.25 * 3
    assert_equal expected, @processor.calculate_total(items)
  end

  test "calculate_total handles missing quantity key" do
    items = [
      { price: 10.50 },
      { price: 5.25, quantity: 3 }
    ]
    expected = 5.25 * 3
    assert_equal expected, @processor.calculate_total(items)
  end

  test "calculate_total skips zero price items" do
    items = [
      { price: 0, quantity: 2 },
      { price: 5.25, quantity: 3 }
    ]
    expected = 5.25 * 3
    assert_equal expected, @processor.calculate_total(items)
  end

  test "calculate_total skips zero quantity items" do
    items = [
      { price: 10.50, quantity: 0 },
      { price: 5.25, quantity: 3 }
    ]
    expected = 5.25 * 3
    assert_equal expected, @processor.calculate_total(items)
  end

  test "calculate_total skips negative price items" do
    items = [
      { price: -10.50, quantity: 2 },
      { price: 5.25, quantity: 3 }
    ]
    expected = 5.25 * 3
    assert_equal expected, @processor.calculate_total(items)
  end

  test "calculate_total skips negative quantity items" do
    items = [
      { price: 10.50, quantity: -2 },
      { price: 5.25, quantity: 3 }
    ]
    expected = 5.25 * 3
    assert_equal expected, @processor.calculate_total(items)
  end

  test "calculate_total handles string values" do
    items = [
      { price: "10.50", quantity: "2" },
      { price: "5.25", quantity: "3" }
    ]
    expected = (10.50 * 2) + (5.25 * 3)
    assert_equal expected, @processor.calculate_total(items)
  end

  test "calculate_total handles invalid string values" do
    items = [
      { price: "invalid", quantity: "also_invalid" },
      { price: 5.25, quantity: 3 }
    ]
    expected = 5.25 * 3
    assert_equal expected, @processor.calculate_total(items)
  end

  # Test other methods to ensure they still work
  test "validate_order works correctly" do
    valid_items = [{ price: 10.50, quantity: 2 }]
    invalid_items = [{ price: 0, quantity: 2 }]
    
    assert @processor.validate_order(valid_items)
    refute @processor.validate_order(invalid_items)
    refute @processor.validate_order(nil)
    refute @processor.validate_order([])
  end

  test "apply_discount works correctly" do
    assert_equal 90.0, @processor.apply_discount(100, 10)
    assert_nil @processor.apply_discount(nil, 10)
    assert_equal 100, @processor.apply_discount(100, nil)
  end

  test "process_payment works correctly" do
    result = @processor.process_payment(100, 'credit_card')
    assert result[:success]
    assert_equal 100, result[:amount]
    assert_equal 'credit_card', result[:method]
    
    result = @processor.process_payment(nil, 'credit_card')
    refute result[:success]
    assert_equal 'Invalid input', result[:error]
  end

  # Tests for the new convert_to_number method
  test "convert_to_number handles nil values" do
    assert_equal 0.0, @processor.convert_to_number(nil)
  end

  test "convert_to_number handles empty string" do
    assert_equal 0.0, @processor.convert_to_number("")
    assert_equal 0.0, @processor.convert_to_number("   ")
  end

  test "convert_to_number handles numeric values" do
    assert_equal 10.5, @processor.convert_to_number(10.5)
    assert_equal 42.0, @processor.convert_to_number(42)
    assert_equal 0.0, @processor.convert_to_number(0)
    assert_equal(-5.5, @processor.convert_to_number(-5.5))
  end

  test "convert_to_number handles string numbers" do
    assert_equal 10.5, @processor.convert_to_number("10.5")
    assert_equal 42.0, @processor.convert_to_number("42")
    assert_equal(-5.5, @processor.convert_to_number("-5.5"))
  end

  test "convert_to_number handles strings with currency symbols" do
    assert_equal 10.50, @processor.convert_to_number("$10.50")
    assert_equal 42.00, @processor.convert_to_number("€42.00")
    assert_equal 25.99, @processor.convert_to_number("£25.99")
  end

  test "convert_to_number handles invalid strings" do
    assert_equal 0.0, @processor.convert_to_number("invalid")
    assert_equal 123.0, @processor.convert_to_number("abc123")
    assert_equal 123.0, @processor.convert_to_number("abc123.00")
  end

  test "convert_to_number handles other data types" do
    assert_equal 0.0, @processor.convert_to_number([])
    assert_equal 0.0, @processor.convert_to_number({})
    assert_equal 0.0, @processor.convert_to_number(true)
  end

  test "convert_to_number handles edge cases that could return nil" do
    assert_equal 0.0, @processor.convert_to_number(Float::INFINITY)
    assert_equal 0.0, @processor.convert_to_number(-Float::INFINITY)
    assert_equal 0.0, @processor.convert_to_number(Float::NAN)
  end

  test "convert_to_number handles strings with commas" do
    assert_equal 1000.50, @processor.convert_to_number("1,000.50")
    assert_equal 1000.50, @processor.convert_to_number("$1,000.50")
  end

  test "calculate_total handles complex edge cases" do
    items = [
      { price: Float::INFINITY, quantity: 2 },
      { price: Float::NAN, quantity: 3 },
      { price: 10.50, quantity: 2 }
    ]
    expected = 10.50 * 2
    assert_equal expected, @processor.calculate_total(items)
  end

  test "calculate_total handles all invalid items" do
    items = [
      { price: 0, quantity: 2 },
      { price: -5, quantity: 3 },
      { price: nil, quantity: nil }
    ]
    assert_equal 0, @processor.calculate_total(items)
  end

  test "calculate_total never returns nil" do
    result = @processor.calculate_total([])
    assert_not_nil result
    assert result.is_a?(Numeric)
    
    result = @processor.calculate_total(nil)
    assert_not_nil result
    assert result.is_a?(Numeric)
  end
end
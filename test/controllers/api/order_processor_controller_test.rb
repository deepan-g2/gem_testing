require 'test_helper'

class Api::OrderProcessorControllerTest < ActionDispatch::IntegrationTest
  test "calculate_total with valid items returns success" do
    post '/api/order_processor/calculate_total', params: {
      items: [
        { price: 10.50, quantity: 2 },
        { price: 5.25, quantity: 3 }
      ]
    }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success']
    expected_total = (10.50 * 2) + (5.25 * 3)
    assert_equal expected_total, json_response['total']
    assert_equal "Total calculated successfully", json_response['message']
  end

  test "calculate_total with empty items returns zero" do
    post '/api/order_processor/calculate_total', params: { items: [] }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success']
    assert_equal 0, json_response['total']
  end

  test "calculate_total with invalid items returns error" do
    post '/api/order_processor/calculate_total', params: {
      items: [
        { price: 0, quantity: 2 }
      ]
    }

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    refute json_response['success']
    assert_equal "Invalid order items", json_response['error']
    assert_equal "All items must have valid price and quantity", json_response['message']
  end

  test "calculate_total with nil values handles gracefully" do
    post '/api/order_processor/calculate_total', params: {
      items: [
        { price: nil, quantity: 2 },
        { price: 10.50, quantity: 3 }
      ]
    }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success']
    expected_total = 10.50 * 3
    assert_equal expected_total, json_response['total']
  end

  test "calculate_total with no params defaults to empty array" do
    post '/api/order_processor/calculate_total'

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success']
    assert_equal 0, json_response['total']
  end

  test "calculate_total with all invalid items returns error" do
    post '/api/order_processor/calculate_total', params: {
      items: [
        { price: 0, quantity: 2 },
        { price: -5, quantity: 1 },
        { price: nil, quantity: 0 }
      ]
    }

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    refute json_response['success']
    assert_equal "Invalid order items", json_response['error']
    assert_equal "All items must have valid price and quantity", json_response['message']
  end

  test "calculate_total with string values works correctly" do
    post '/api/order_processor/calculate_total', params: {
      items: [
        { price: "10.50", quantity: "2" },
        { price: "$5.25", quantity: "3" }
      ]
    }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success']
    expected_total = (10.50 * 2) + (5.25 * 3)
    assert_equal expected_total, json_response['total']
  end

  test "calculate_total handles malformed data that could cause nil coercion error" do
    # Test the exact types of data that could cause "nil can't be coerced into Integer"
    post '/api/order_processor/calculate_total', params: {
      items: [
        { price: "NaN", quantity: "Infinity" },
        { price: "", quantity: "" },
        { price: "invalid", quantity: "bad" },
        { price: 10.50, quantity: 2 }  # One valid item
      ]
    }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success']
    assert_equal 21.0, json_response['total']  # Only the valid item should be calculated
    assert json_response['total'].is_a?(Numeric)
  end

  test "calculate_total handles extreme edge cases without errors" do
    post '/api/order_processor/calculate_total', params: {
      items: [
        { price: Float::NAN, quantity: Float::INFINITY },
        { price: nil, quantity: nil },
        {},  # empty hash
        { price: [], quantity: {} },  # wrong data types
        { price: true, quantity: false },  # boolean values
      ]
    }

    # Should still return success with total 0, not crash with nil coercion error
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success']
    assert_equal 0, json_response['total']
    assert json_response['total'].is_a?(Numeric)
  end
end
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

  test "calculate_total handles edge cases that previously caused TypeError" do
    post '/api/order_processor/calculate_total', params: {
      items: [
        { price: Float::INFINITY, quantity: 2 },
        { price: Float::NAN, quantity: 3 },
        { price: "invalid", quantity: "also_invalid" },
        { price: "$$$", quantity: "€€€" },
        { price: nil, quantity: nil },
        { price: 10.50, quantity: 2 }  # Only this should contribute to total
      ]
    }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success']
    expected_total = 10.50 * 2
    assert_equal expected_total, json_response['total']
    assert json_response['total'].is_a?(Numeric)
  end

  test "calculate_total never returns error for malformed data that caused original TypeError" do
    # This test specifically addresses the original error scenario
    post '/api/order_processor/calculate_total', params: {
      items: [
        { price: nil, quantity: 2 },  # This was causing the original TypeError
        { price: "not_a_number", quantity: "also_not_a_number" },
        { price: "", quantity: "" },
        { price: "   ", quantity: "   " }
      ]
    }

    # Should not cause a 500 error, should handle gracefully
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success']
    assert_equal 0, json_response['total']  # All items are invalid, so total should be 0
  end
end
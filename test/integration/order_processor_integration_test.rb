require 'test_helper'

class OrderProcessorIntegrationTest < ActionDispatch::IntegrationTest
  test "calculate_total handles the original error case that caused TypeError" do
    # This test specifically targets the "nil can't be coerced into Integer" error
    # by sending the exact type of data that would cause the original error
    
    post '/api/order_processor/calculate_total', params: {
      items: [
        { price: nil, quantity: 2 },  # This would cause the original error
        { price: 10.50, quantity: nil }  # This would also cause the original error
      ]
    }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success']
    # Should return 0 since both items have nil values that make them invalid
    assert_equal 0, json_response['total']
  end

  test "calculate_total handles complex edge case that could trigger TypeError" do
    post '/api/order_processor/calculate_total', params: {
      items: [
        nil,  # Nil item in array
        { price: Float::INFINITY, quantity: 2 },  # Infinity values
        { price: Float::NAN, quantity: 3 },  # NaN values
        { price: "invalid_string", quantity: "bad_string" },  # Invalid strings
        {},  # Empty hash
        { price: 10.50, quantity: 2 }  # One valid item
      ]
    }

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success']
    # Should only calculate the valid item: 10.50 * 2 = 21.0
    assert_equal 21.0, json_response['total']
  end

  test "calculate_total never returns nil or causes coercion errors" do
    # Test various problematic inputs that could cause the original error
    problematic_inputs = [
      nil,
      [],
      [nil],
      [{}],
      [{ price: nil, quantity: nil }],
      [{ price: "", quantity: "" }],
      [{ price: "abc", quantity: "xyz" }],
      [{ price: Float::INFINITY, quantity: Float::NAN }]
    ]

    problematic_inputs.each_with_index do |items, index|
      post '/api/order_processor/calculate_total', params: { items: items }
      
      # Should never fail with a 500 error
      assert_response :success, "Failed for input #{index}: #{items.inspect}"
      
      json_response = JSON.parse(response.body)
      assert json_response['success'], "Response not successful for input #{index}: #{items.inspect}"
      
      # Total should always be a number, never nil
      assert json_response['total'].is_a?(Numeric), "Total is not numeric for input #{index}: #{items.inspect}"
      assert json_response['total'].finite?, "Total is not finite for input #{index}: #{items.inspect}"
    end
  end

  test "calculate_total logs errors appropriately but never crashes" do
    # This test ensures that even if there are unexpected errors,
    # they're caught and logged appropriately without crashing
    
    # Simulate a scenario that might cause internal errors
    post '/api/order_processor/calculate_total', params: {
      items: [
        { price: "definitely_not_a_number", quantity: "also_not_a_number" }
      ]
    }

    # Should still succeed because our error handling is comprehensive
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success']
    assert_equal 0, json_response['total']  # Invalid items should result in 0 total
  end

  test "calculate_total handles ActionController::Parameters properly" do
    # Rails wraps parameters in ActionController::Parameters
    # which can behave differently than regular hashes
    
    post '/api/order_processor/calculate_total', params: {
      items: [
        { 
          price: { nested: "10.50" },  # Nested parameter that's invalid
          quantity: 2 
        },
        {
          price: "15.75",
          quantity: { nested: "3" }  # Nested parameter that's invalid
        }
      ]
    }

    # Should handle gracefully without throwing errors
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success']
    # Both items should be invalid due to nested parameters
    assert_equal 0, json_response['total']
  end
end
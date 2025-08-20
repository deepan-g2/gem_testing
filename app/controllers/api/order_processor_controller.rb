class Api::OrderProcessorController < ApplicationController
  skip_before_action :verify_authenticity_token

  def calculate_total
    items = params[:items] || []

    # Convert Rails parameters to regular hashes
    items = items.map { |item| item.to_unsafe_h.symbolize_keys } if items.any?

    processor = OrderProcessor.new
    
    # Check if all items have zero/negative/invalid values and should return error
    if items.any? && items.all? { |item| should_be_invalid?(item, processor) }
      render json: {
        success: false,
        error: "Invalid order items", 
        message: "All items must have valid price and quantity"
      }, status: :bad_request
      return
    end

    result = processor.calculate_total(items)

    render json: {
      success: true,
      total: result,
      items: items,
      message: "Total calculated successfully"
    }
  end

  private

  def should_be_invalid?(item, processor)
    return false if item.nil?
    
    price = item[:price]
    quantity = item[:quantity]
    
    # Convert to numeric values using the same logic as the model
    price_num = processor.convert_to_number(price)
    quantity_num = processor.convert_to_number(quantity)
    
    # Item is invalid if either price or quantity are <= 0
    price_num <= 0 || quantity_num <= 0
  end
end
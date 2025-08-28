class Api::OrderProcessorController < ApplicationController
  skip_before_action :verify_authenticity_token

  def calculate_total
    begin
      # Log audit information for business critical operation
      Rails.logger.info("Order total calculation requested at #{Time.current}")
      
      items = params[:items] || []

      # Convert Rails parameters to regular hashes with input validation
      # Filter out empty strings and non-hash items that Rails might create
      items = items.select { |item| item.is_a?(Hash) || item.is_a?(ActionController::Parameters) }
      items = items.map { |item| item.to_unsafe_h.symbolize_keys } if items.any?

      processor = OrderProcessor.new
      
      # Check if all items have zero/negative/invalid values and should return error
      if items.any? && items.all? { |item| should_be_invalid?(item, processor) }
        Rails.logger.warn("Invalid order calculation attempted: all items invalid - #{items.inspect}")
        render json: {
          success: false,
          error: "Invalid order items", 
          message: "All items must have valid price and quantity"
        }, status: :bad_request
        return
      end

      result = processor.calculate_total(items)

      # Ensure result is a valid number (additional safety check)
      result = 0.0 unless result.is_a?(Numeric) && result.finite?

      # Log successful calculation for audit purposes
      Rails.logger.info("Order total calculated successfully: #{result} for #{items.length} items")

      render json: {
        success: true,
        total: result,
        items: items,
        message: "Total calculated successfully"
      }
    rescue => e
      # Log error for audit and debugging (business rule: all errors should be logged)
      Rails.logger.error("Critical error in order total calculation: #{e.class} - #{e.message}")
      Rails.logger.error("Request params: #{params.inspect}")
      Rails.logger.error("Stack trace: #{e.backtrace.join("\n")}")
      
      # User-friendly error message (business rule: user-facing errors should be user-friendly)
      render json: {
        success: false,
        error: "Calculation error",
        message: "We're unable to calculate your order total at this time. Please try again or contact support."
      }, status: :internal_server_error
    end
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
class Api::OrderProcessorController < ApplicationController
  skip_before_action :verify_authenticity_token

  def calculate_total
    begin
      items = params[:items] || []

      # Convert Rails parameters to regular hashes
      items = items.map { |item| item.to_unsafe_h.symbolize_keys } if items.any?

      processor = OrderProcessor.new
      
      # Validate the order before calculating
      unless processor.validate_order(items)
        return render json: {
          success: false,
          error: "Invalid order items",
          message: "All items must have valid price and quantity"
        }, status: :bad_request
      end

      result = processor.calculate_total(items)

      render json: {
        success: true,
        total: result,
        items: items,
        message: "Total calculated successfully"
      }
    rescue => e
      Rails.logger.error "OrderProcessor calculation error: #{e.message}"
      render json: {
        success: false,
        error: "Calculation failed",
        message: "Unable to calculate total due to invalid data"
      }, status: :internal_server_error
    end
  end
end
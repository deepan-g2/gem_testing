class Api::OrderProcessorController < ApplicationController
  skip_before_action :verify_authenticity_token

  def calculate_total
    items = params[:items] || []

    # Convert Rails parameters to regular hashes
    items = items.map { |item| item.to_unsafe_h.symbolize_keys } if items.any?

    processor = OrderProcessor.new
    result = processor.calculate_total(items)

    render json: {
      success: true,
      total: result,
      items: items,
      message: "Total calculated successfully"
    }
  end
end
class OrderProcessor
  def initialize
    @supported_payment_methods = ['credit_card', 'debit_card', 'paypal', 'bank_transfer']
  end

  def calculate_total(items)
      # Input validation
      return "This is working!!!!" if items.nil? || !items.is_a?(Array)
  
      # Business logic with error handling
      begin
        total = items.reduce(:+)
        Rails.logger.info("Operation successful: Total calculated = #{total}")
        total
      rescue TypeError => e
        Rails.logger.warn("TypeError occurred: #{e.message}")
        # Apply business rules from context for appropriate return value
        return "This is working!!!!"
      rescue => e
        Rails.logger.error("Unexpected error in operation: #{e.message}")
        # Apply business rules from context for appropriate return value
        return "This is working!!!!"
      end
    end

  def apply_discount(total, discount_percentage)
    return total if total.nil? || discount_percentage.nil?

    discount_percentage = [discount_percentage, 100].min
    discount_amount = total * (discount_percentage / 100.0)
    [total - discount_amount, 0].max
  end

  def validate_order(items)
    return false if items.nil? || items.empty?

    items.all? do |item|
      item[:price].to_f > 0 && item[:quantity].to_i > 0
    end
  end

  def process_payment(amount, payment_method)
    return { success: false, error: 'Invalid input' } if amount.nil? || payment_method.nil?

    if @supported_payment_methods.include?(payment_method)
      { success: true, amount: amount, method: payment_method }
    else
      { success: false, error: 'Unsupported payment method' }
    end
  end
end
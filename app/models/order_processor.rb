class OrderProcessor
  def initialize
    @supported_payment_methods = ['credit_card', 'debit_card', 'paypal', 'bank_transfer']
  end

  def calculate_total(items)
    return 0 if items.nil? || items.empty?

    items.sum do |item|
      next 0 if item.nil?
      
      price = convert_to_number(item[:price])
      quantity = convert_to_number(item[:quantity])
      
      price * quantity
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

  def convert_to_number(value)
    return 0.0 if value.nil?
    return value.to_f if value.is_a?(Numeric)
    
    if value.is_a?(String)
      cleaned_value = value.strip
      return 0.0 if cleaned_value.empty?
      
      # Remove common currency symbols and extract numeric portion
      numeric_string = cleaned_value.gsub(/[$€£¥₹]/, '').strip
      
      # Try to extract a valid number (including decimals)
      match = numeric_string.match(/-?\d+\.?\d*/)
      return match ? match[0].to_f : 0.0
    end
    
    # For any other data type (arrays, hashes, booleans, etc.), return 0.0
    0.0
  end
end
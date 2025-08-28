class OrderProcessor
  def initialize
    @supported_payment_methods = ['credit_card', 'debit_card', 'paypal', 'bank_transfer']
  end

  def calculate_total(items)
    return 0 if items.nil? || items.empty?

    total = 0
    items.each do |item|
      next if item.nil?
      
      price = convert_to_number(item[:price])
      quantity = convert_to_number(item[:quantity])
      
      # Skip items with zero or negative values (business rule)
      next if price <= 0 || quantity <= 0
      
      total += price * quantity
    end
    
    total
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
    # Always return a numeric value, never nil
    return 0.0 if value.nil?
    
    if value.is_a?(Numeric)
      # Handle infinity and NaN cases
      return 0.0 unless value.finite?
      return value.to_f
    end
    
    if value.is_a?(String)
      cleaned_value = value.strip
      return 0.0 if cleaned_value.empty?
      
      # Remove common currency symbols and commas
      numeric_string = cleaned_value.gsub(/[$€£¥₹,]/, '').strip
      
      # Try to extract a valid number (including decimals)
      # Updated regex to be more precise and handle edge cases
      match = numeric_string.match(/-?\d+(?:\.\d+)?/)
      result = match ? match[0].to_f : 0.0
      
      # Ensure result is always a valid number
      return result.finite? ? result : 0.0
    end
    
    # For any other data type (arrays, hashes, booleans, etc.), return 0.0
    0.0
  rescue => e
    # In case of any unexpected error, log it and return 0.0
    Rails.logger.error("Error converting value to number: #{e.message}") if defined?(Rails)
    0.0
  end
end
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
      
      # Ensure we have valid numeric values before proceeding
      next unless price.is_a?(Numeric) && quantity.is_a?(Numeric)
      next unless price.finite? && quantity.finite?
      
      # Skip items with zero or negative values (business rule)
      next if price <= 0 || quantity <= 0
      
      # Perform multiplication with additional nil safety
      line_total = price * quantity
      next unless line_total.is_a?(Numeric) && line_total.finite?
      
      total += line_total
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
    
    # Handle numeric values
    if value.is_a?(Numeric)
      # Ensure the numeric value is finite and valid
      return value.finite? ? value.to_f : 0.0
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
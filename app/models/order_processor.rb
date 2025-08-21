class OrderProcessor
  def initialize
    @supported_payment_methods = ['credit_card', 'debit_card', 'paypal', 'bank_transfer']
  end

  def calculate_total(items)
    return 0.0 if items.nil? || items.empty?

    total = 0.0
    items.each do |item|
      next if item.nil?
      
      price = convert_to_number(item[:price])
      quantity = convert_to_number(item[:quantity])
      
      # Additional safety check to ensure both values are numeric and finite
      next unless price.is_a?(Numeric) && quantity.is_a?(Numeric)
      next unless price.finite? && quantity.finite?
      
      # Skip items with zero or negative values (business rule)
      next if price <= 0 || quantity <= 0
      
      item_total = price * quantity
      # Ensure the multiplication result is also valid
      next unless item_total.finite?
      
      total += item_total
    end
    
    # Ensure final result is always a valid finite number
    total.finite? ? total : 0.0
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
    
    # Handle numeric values, checking for validity
    if value.is_a?(Numeric)
      return value.finite? ? value.to_f : 0.0
    end
    
    # Handle string values
    if value.is_a?(String)
      cleaned_value = value.strip
      return 0.0 if cleaned_value.empty?
      
      # Remove common currency symbols and commas
      numeric_string = cleaned_value.gsub(/[$€£¥₹,]/, '').strip
      return 0.0 if numeric_string.empty?
      
      # Try to extract a valid number (including decimals)
      # Use anchored regex to match entire string for better precision
      if numeric_string.match(/\A-?\d+(?:\.\d+)?\z/)
        result = numeric_string.to_f
        # Ensure result is always a valid finite number
        return result.finite? ? result : 0.0
      end
      
      # If no exact match, try to extract the first valid number
      match = numeric_string.match(/-?\d+(?:\.\d+)?/)
      if match
        result = match[0].to_f
        return result.finite? ? result : 0.0
      end
      
      return 0.0
    end
    
    # For any other data type (arrays, hashes, booleans, etc.), return 0.0
    0.0
  rescue StandardError => e
    # In case of any unexpected error, log it and return 0.0
    Rails.logger.error("Error converting value to number: #{e.message}") if defined?(Rails)
    0.0
  end
end
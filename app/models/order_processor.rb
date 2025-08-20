class OrderProcessor
  def initialize
    @supported_payment_methods = ['credit_card', 'debit_card', 'paypal', 'bank_transfer']
  end

  def calculate_total(items)
    return 0 if items.nil? || items.empty?

    items.sum do |item|
      next 0 if item.nil?
      
      price = item[:price]
      quantity = item[:quantity]
      
      # Convert to numeric values, handling strings and nil
      price_num = convert_to_number(price)
      quantity_num = convert_to_number(quantity)
      
      # Only include items with positive price and quantity
      next 0 if price_num <= 0 || quantity_num <= 0
      
      price_num * quantity_num
    end
  end

  def convert_to_number(value)
    return 0 if value.nil?
    
    case value
    when Numeric
      value.to_f
    when String
      Float(value) rescue 0
    else
      0
    end
  end

  private

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
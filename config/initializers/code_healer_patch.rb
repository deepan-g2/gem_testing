# Monkey patch to fix ActiveRecord::UnknownAttributeReference error in CodeHealer gem
# This patch fixes the raw SQL usage in HealingMetric#hourly_healing_distribution

Rails.application.config.after_initialize do
  # Only apply the patch if the CodeHealer module exists
  if defined?(CodeHealer) && defined?(CodeHealer::HealingMetric)
    CodeHealer::HealingMetric.class_eval do
      # Override the problematic hourly_healing_distribution method
      def self.hourly_healing_distribution
        # Use Arel.sql to safely wrap the raw SQL expression
        group(Arel.sql("EXTRACT(HOUR FROM created_at)"))
          .group(:status)
          .count
      rescue StandardError => e
        Rails.logger.error "Error in HealingMetric#hourly_healing_distribution: #{e.message}"
        # Return a safe default structure
        {}
      end
    end
  end
end
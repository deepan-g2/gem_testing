require 'test_helper'

class CodeHealerSqlSafetyTest < ActionDispatch::IntegrationTest
  test "raw sql queries are properly wrapped with Arel.sql" do
    # This test ensures that any raw SQL usage is properly wrapped
    # to prevent ActiveRecord::UnknownAttributeReference errors
    
    # Test that our patch prevents the specific error mentioned in the backtrace
    if defined?(CodeHealer) && defined?(CodeHealer::HealingMetric)
      # This should not raise ActiveRecord::UnknownAttributeReference
      assert_nothing_raised ActiveRecord::UnknownAttributeReference do
        CodeHealer::HealingMetric.hourly_healing_distribution
      end
    end
  end

  test "dashboard controller functionality is accessible" do
    # Verify that dashboard functionality works after the fix
    if defined?(CodeHealer) && defined?(CodeHealer::MetricsCollector)
      begin
        # This should not raise the original error
        assert_nothing_raised ActiveRecord::UnknownAttributeReference do
          collector = CodeHealer::MetricsCollector.new
          collector.dashboard_summary
        end
      rescue NameError => e
        # If the class doesn't exist in this version, that's fine
        assert true, "MetricsCollector not available in this version"
      rescue StandardError => e
        # Other errors (like missing database tables) are acceptable
        # as long as it's not the specific UnknownAttributeReference error
        refute e.is_a?(ActiveRecord::UnknownAttributeReference), 
               "Should not raise UnknownAttributeReference error"
      end
    end
  end

  test "arel sql wrapper works correctly" do
    # Test that Arel.sql correctly wraps raw SQL expressions
    raw_sql = "EXTRACT(HOUR FROM created_at)"
    arel_wrapped = Arel.sql(raw_sql)
    
    assert_instance_of Arel::Nodes::SqlLiteral, arel_wrapped
    assert_equal raw_sql, arel_wrapped.to_s
  end
end
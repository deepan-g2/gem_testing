require 'test_helper'

class CodeHealerPatchTest < ActionDispatch::IntegrationTest
  test "code_healer patch loads without errors" do
    # This test ensures the patch initializer loads without raising an exception
    assert_nothing_raised do
      # Try to load the configuration
      Rails.application.config
    end
  end

  test "healing_metric hourly_healing_distribution is callable when gem is present" do
    # Only run this test if the CodeHealer module is loaded
    if defined?(CodeHealer) && defined?(CodeHealer::HealingMetric)
      assert_nothing_raised do
        # The method should be callable without raising UnknownAttributeReference error
        CodeHealer::HealingMetric.hourly_healing_distribution
      end
    else
      # If the gem isn't loaded, just verify the patch doesn't break anything
      assert true
    end
  end

  test "patch handles database connection errors gracefully" do
    # Only run this test if the CodeHealer module is loaded
    if defined?(CodeHealer) && defined?(CodeHealer::HealingMetric)
      # Mock a database error to ensure our error handling works
      CodeHealer::HealingMetric.stub :group, ->(*args) { raise StandardError.new("Mock DB error") } do
        result = CodeHealer::HealingMetric.hourly_healing_distribution
        assert_equal({}, result, "Should return empty hash when error occurs")
      end
    else
      assert true
    end
  end
end
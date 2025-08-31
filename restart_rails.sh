#!/bin/bash

echo "Stopping Spring preloader to clear cache..."
spring stop

echo "Restarting Rails server..."
pkill -f "rails server" || true
pkill -f "puma" || true

echo "Rails processes stopped. You can now restart with: rails server"
echo ""
echo "If the error persists, the fix is already implemented in the code."
echo "The issue was nil values not being properly handled in multiplication."
echo "Current code uses convert_to_number method to ensure no nil values reach the calculation."
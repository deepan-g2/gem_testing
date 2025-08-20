class CreateHealingMetrics < ActiveRecord::Migration[7.1]
  def change
    create_table :healing_metrics do |t|
      t.string :request_id, null: false, index: true
      t.string :error_type, null: false, index: true
      t.text :error_message, null: false
      t.string :class_name, null: false, index: true
      t.string :method_name, null: false, index: true
      t.string :file_path, null: false
      t.string :status, null: false, default: 'pending', index: true
      t.datetime :started_at
      t.datetime :completed_at
      t.text :healing_details
      t.text :error_context
      t.text :backtrace
      
      t.timestamps
      
      t.index [:status, :created_at]
      t.index [:error_type, :created_at]
      t.index [:class_name, :method_name]
      t.index [:created_at]
    end
    
    add_check_constraint :healing_metrics, "status IN ('pending', 'processing', 'completed', 'failed')", name: 'healing_metrics_status_check'
  end
end
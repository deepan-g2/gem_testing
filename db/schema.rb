# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_08_20_190551) do
  create_table "healing_metrics", force: :cascade do |t|
    t.string "healing_id", null: false
    t.string "class_name", null: false
    t.string "method_name", null: false
    t.string "error_class", null: false
    t.text "error_message"
    t.string "file_path"
    t.string "evolution_method"
    t.string "ai_provider"
    t.boolean "ai_success", default: false
    t.text "ai_response"
    t.integer "ai_tokens_used"
    t.decimal "ai_cost", precision: 10, scale: 4
    t.string "workspace_path"
    t.string "healing_branch"
    t.string "pull_request_url"
    t.boolean "pr_created", default: false
    t.datetime "error_occurred_at"
    t.datetime "healing_started_at"
    t.datetime "healing_completed_at"
    t.integer "total_duration_ms"
    t.integer "ai_processing_time_ms"
    t.integer "git_operations_time_ms"
    t.boolean "healing_successful", default: false
    t.boolean "tests_passed", default: false
    t.boolean "syntax_valid", default: false
    t.text "failure_reason"
    t.text "business_context_used"
    t.string "jira_issue_id"
    t.string "confluence_page_id"
    t.json "additional_metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["class_name", "method_name"], name: "index_healing_metrics_on_class_name_and_method_name"
    t.index ["created_at"], name: "index_healing_metrics_on_created_at"
    t.index ["evolution_method", "ai_provider"], name: "index_healing_metrics_on_evolution_method_and_ai_provider"
    t.index ["healing_id"], name: "index_healing_metrics_on_healing_id"
    t.index ["healing_successful", "created_at"], name: "index_healing_metrics_on_healing_successful_and_created_at"
  end

end

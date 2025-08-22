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

ActiveRecord::Schema[8.0].define(version: 2025_08_22_222216) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.string "stripe_customer_id"
    t.string "subscription_status"
    t.string "plan_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "monitor_checks", force: :cascade do |t|
    t.bigint "site_monitor_id", null: false
    t.integer "status_code"
    t.float "response_time"
    t.datetime "checked_at"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_monitor_id"], name: "index_monitor_checks_on_site_monitor_id"
  end

  create_table "site_monitors", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.bigint "company_id", null: false
    t.string "status"
    t.datetime "last_checked_at"
    t.integer "check_interval"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_site_monitors_on_company_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "stripe_subscription_id"
    t.string "plan_name"
    t.string "status"
    t.datetime "current_period_end"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_subscriptions_on_company_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name"
    t.string "last_name"
    t.bigint "company_id"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "monitor_checks", "site_monitors"
  add_foreign_key "site_monitors", "companies"
  add_foreign_key "subscriptions", "companies"
end

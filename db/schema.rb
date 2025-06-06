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

ActiveRecord::Schema[8.0].define(version: 2025_06_06_015428) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "email_subscriptions", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_email_subscriptions_on_email", unique: true
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.date "birth_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "gender", null: false, comment: "0: male, 1: female"
    t.integer "height_cm", null: false, comment: "Height in centimeters"
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.datetime "revoked_at"
    t.text "revocation_reason"
    t.inet "revoked_from_ip"
    t.datetime "replaced_at"
    t.integer "replaced_by"
    t.inet "issued_from_ip"
    t.text "user_agent"
    t.index ["replaced_by"], name: "index_refresh_tokens_on_replaced_by"
    t.index ["revoked_at"], name: "index_refresh_tokens_on_revoked_at"
    t.index ["status"], name: "index_refresh_tokens_on_status"
    t.index ["token"], name: "index_refresh_tokens_on_token", unique: true
    t.index ["user_id", "status"], name: "index_refresh_tokens_on_user_id_and_status"
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "unit_system", default: 0, null: false
    t.integer "activity_level", default: 0, null: false
    t.integer "weight_goal_type", default: 0, null: false
    t.decimal "weight_goal_rate", precision: 3, scale: 1, default: "0.0", null: false
    t.integer "diet_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_settings_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "refresh_token_digest"
    t.datetime "refresh_token_expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "weights", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.float "weight_kg", null: false, comment: "Weight in kilograms"
    t.datetime "recorded_at", null: false, comment: "When the weight was recorded"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recorded_at"], name: "index_weights_on_recorded_at"
    t.index ["user_id", "recorded_at"], name: "index_weights_on_user_and_recorded_at"
    t.index ["user_id"], name: "index_weights_on_user_id"
  end

  add_foreign_key "profiles", "users"
  add_foreign_key "refresh_tokens", "users"
  add_foreign_key "settings", "users"
  add_foreign_key "weights", "users"
end

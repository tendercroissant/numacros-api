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

ActiveRecord::Schema[8.0].define(version: 2025_06_08_214445) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "email_subscriptions", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_email_subscriptions_on_email", unique: true
  end

  create_table "nutrition_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "activity_level", default: 0, null: false
    t.integer "goal", default: 0, null: false
    t.decimal "rate", precision: 3, scale: 1, default: "0.0", null: false
    t.integer "diet_type", default: 0, null: false
    t.integer "target_calories"
    t.integer "target_protein_g"
    t.integer "target_carbs_g"
    t.integer "target_fat_g"
    t.integer "bmr"
    t.integer "tdee"
    t.datetime "calculated_at"
    t.integer "custom_protein_g"
    t.integer "custom_carbs_g"
    t.integer "custom_fat_g"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_nutrition_profiles_on_user_id"
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

  create_table "user_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.integer "sex", null: false
    t.date "birth_date", null: false
    t.decimal "height_cm", precision: 5, scale: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_profiles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "weights", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "weight_kg", precision: 5, scale: 1, null: false
    t.datetime "recorded_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recorded_at"], name: "index_weights_on_recorded_at"
    t.index ["user_id", "recorded_at"], name: "index_weights_on_user_id_and_recorded_at", unique: true
    t.index ["user_id"], name: "index_weights_on_user_id"
  end

  add_foreign_key "nutrition_profiles", "users"
  add_foreign_key "refresh_tokens", "users"
  add_foreign_key "user_profiles", "users"
  add_foreign_key "weights", "users"
end

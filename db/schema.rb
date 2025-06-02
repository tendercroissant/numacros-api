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

ActiveRecord::Schema[8.0].define(version: 2025_06_02_001202) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "email_subscriptions", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_email_subscriptions_on_email", unique: true
  end

  create_table "macronutrient_targets", force: :cascade do |t|
    t.bigint "user_profile_id", null: false
    t.integer "calories", null: false
    t.integer "carbs_grams", null: false
    t.integer "protein_grams", null: false
    t.integer "fat_grams", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_profile_id"], name: "index_macronutrient_targets_on_user_profile_id", unique: true
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_refresh_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "user_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.date "birth_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "gender", null: false, comment: "0: male, 1: female"
    t.float "weight_kg", null: false, comment: "Weight in kilograms"
    t.integer "height_cm", null: false, comment: "Height in centimeters"
    t.integer "unit_system", default: 0, null: false, comment: "0: metric, 1: imperial"
    t.integer "activity_level", default: 0, null: false, comment: "0: sedentary (1.2), 1: lightly_active (1.375), 2: moderately_active (1.55), 3: very_active (1.725), 4: extra_active (1.9)"
    t.integer "weight_goal_type", default: 1, null: false, comment: "0: lose_weight, 1: maintain_weight, 2: build_muscle"
    t.float "weight_goal_rate", default: 0.0, null: false, comment: "Rate in pounds per week: 0.0, 0.5, 1.0, 2.0"
    t.integer "dietary_type", default: 0, null: false
    t.float "custom_carbs_percent"
    t.float "custom_protein_percent"
    t.float "custom_fat_percent"
    t.index ["activity_level"], name: "index_user_profiles_on_activity_level"
    t.index ["dietary_type"], name: "index_user_profiles_on_dietary_type"
    t.index ["gender"], name: "index_user_profiles_on_gender"
    t.index ["unit_system"], name: "index_user_profiles_on_unit_system"
    t.index ["user_id"], name: "index_user_profiles_on_user_id"
    t.index ["weight_goal_type"], name: "index_user_profiles_on_weight_goal_type"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "macronutrient_targets", "user_profiles"
  add_foreign_key "refresh_tokens", "users"
  add_foreign_key "user_profiles", "users"
end

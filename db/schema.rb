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

ActiveRecord::Schema[7.1].define(version: 2024_04_28_160252) do
  create_table "items", force: :cascade do |t|
    t.integer "status"
    t.integer "kind"
    t.boolean "icebox", default: true
    t.boolean "in_progress", default: false
    t.boolean "done", default: false
    t.string "name"
    t.text "description"
    t.integer "points"
    t.integer "position", null: false
    t.datetime "accepted_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "delivered_at"
    t.integer "user_id"
    t.integer "sprint_id"
    t.integer "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_items_on_project_id"
    t.index ["sprint_id"], name: "index_items_on_sprint_id"
    t.index ["user_id"], name: "index_items_on_user_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.date "start_date"
    t.integer "velocity"
    t.integer "volatility"
    t.integer "sprint_length"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sprints", force: :cascade do |t|
    t.date "start_date"
    t.date "end_date"
    t.integer "length"
    t.integer "velocity"
    t.integer "strength"
    t.integer "number"
    t.integer "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_sprints_on_project_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "pseudonym"
    t.string "name"
    t.string "last_name"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "items", "projects"
  add_foreign_key "items", "sprints"
  add_foreign_key "items", "users"
  add_foreign_key "sprints", "projects"
end

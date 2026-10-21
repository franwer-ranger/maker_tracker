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

ActiveRecord::Schema[8.1].define(version: 2026_10_22_224800) do
  create_table "actors", force: :cascade do |t|
    t.string "name", null: false
    t.string "kind", null: false
    t.string "token_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "token_used_at"
    t.index ["name"], name: "index_actors_on_name", unique: true
    t.index ["token_digest"], name: "index_actors_on_token_digest", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.integer "story_id", null: false
    t.integer "actor_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_comments_on_actor_id"
    t.index ["story_id"], name: "index_comments_on_story_id"
  end

  create_table "decisions", force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "story_id"
    t.integer "actor_id", null: false
    t.integer "supersedes_id"
    t.integer "number", null: false
    t.string "title", null: false
    t.text "body", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_decisions_on_actor_id"
    t.index ["project_id", "number"], name: "index_decisions_on_project_id_and_number", unique: true
    t.index ["project_id"], name: "index_decisions_on_project_id"
    t.index ["story_id"], name: "index_decisions_on_story_id"
    t.index ["supersedes_id"], name: "index_decisions_on_supersedes_id"
  end

  create_table "events", force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "story_id"
    t.integer "actor_id", null: false
    t.string "action", null: false
    t.json "data", default: {}, null: false
    t.text "reason"
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.index ["actor_id"], name: "index_events_on_actor_id"
    t.index ["project_id", "action"], name: "index_events_on_project_id_and_action"
    t.index ["project_id", "occurred_at"], name: "index_events_on_project_id_and_occurred_at"
    t.index ["project_id"], name: "index_events_on_project_id"
    t.index ["story_id", "occurred_at"], name: "index_events_on_story_id_and_occurred_at"
    t.index ["story_id"], name: "index_events_on_story_id"
  end

  create_table "milestones", force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "title", null: false
    t.text "goal", default: "", null: false
    t.integer "position", null: false
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "version", default: 1, null: false
    t.index ["project_id", "position"], name: "index_milestones_on_project_id_and_position", unique: true
    t.index ["project_id"], name: "index_milestones_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "key", null: false
    t.text "brief", default: "", null: false
    t.json "settings", default: {}, null: false
    t.integer "last_story_number", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "last_decision_number", default: 0, null: false
    t.integer "brief_version", default: 1, null: false
    t.datetime "last_pushed_at"
    t.datetime "ready_low_notified_at"
    t.index ["key"], name: "index_projects_on_key", unique: true
    t.index ["slug"], name: "index_projects_on_slug", unique: true
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.integer "actor_id", null: false
    t.text "endpoint", null: false
    t.string "p256dh", null: false
    t.string "auth", null: false
    t.string "user_agent"
    t.datetime "last_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_push_subscriptions_on_actor_id"
    t.index ["endpoint"], name: "index_push_subscriptions_on_endpoint", unique: true
  end

  create_table "questions", force: :cascade do |t|
    t.integer "story_id", null: false
    t.integer "actor_id", null: false
    t.string "title", null: false
    t.text "context", default: "", null: false
    t.json "options", default: [], null: false
    t.integer "recommended"
    t.boolean "reversible"
    t.boolean "blocking", default: true, null: false
    t.integer "answer"
    t.text "answer_note"
    t.integer "answered_by_id"
    t.datetime "answered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_questions_on_actor_id"
    t.index ["answered_at"], name: "index_questions_on_answered_at"
    t.index ["answered_by_id"], name: "index_questions_on_answered_by_id"
    t.index ["story_id"], name: "index_questions_on_story_id"
  end

  create_table "stories", force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "milestone_id"
    t.integer "number", null: false
    t.string "title", null: false
    t.text "body", default: "", null: false
    t.json "properties", default: {}, null: false
    t.string "state", default: "idea", null: false
    t.integer "position", null: false
    t.integer "claimed_by_id"
    t.datetime "claimed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "version", default: 1, null: false
    t.string "qa"
    t.datetime "deployed_at"
    t.index ["claimed_by_id"], name: "index_stories_on_claimed_by_id"
    t.index ["milestone_id"], name: "index_stories_on_milestone_id"
    t.index ["project_id", "milestone_id", "position"], name: "index_stories_on_project_id_and_milestone_id_and_position", unique: true
    t.index ["project_id", "number"], name: "index_stories_on_project_id_and_number", unique: true
    t.index ["project_id", "state"], name: "index_stories_on_project_id_and_state"
    t.index ["project_id"], name: "index_stories_on_project_id"
    t.index ["qa"], name: "index_stories_on_qa", where: "qa IS NOT NULL"
  end

  create_table "visits", force: :cascade do |t|
    t.string "key", null: false
    t.integer "story_id"
    t.datetime "since", null: false
    t.datetime "seen_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_visits_on_key", unique: true
    t.index ["story_id"], name: "index_visits_on_story_id"
  end

  add_foreign_key "comments", "actors"
  add_foreign_key "comments", "stories"
  add_foreign_key "decisions", "actors"
  add_foreign_key "decisions", "decisions", column: "supersedes_id"
  add_foreign_key "decisions", "projects"
  add_foreign_key "decisions", "stories"
  add_foreign_key "events", "actors"
  add_foreign_key "events", "projects"
  add_foreign_key "events", "stories"
  add_foreign_key "milestones", "projects"
  add_foreign_key "push_subscriptions", "actors"
  add_foreign_key "questions", "actors"
  add_foreign_key "questions", "actors", column: "answered_by_id"
  add_foreign_key "questions", "stories"
  add_foreign_key "stories", "actors", column: "claimed_by_id"
  add_foreign_key "stories", "milestones"
  add_foreign_key "stories", "projects"
  add_foreign_key "visits", "stories"
end

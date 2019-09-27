# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_09_10_005423) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "answers", id: :bigint, default: nil, force: :cascade do |t|
    t.boolean "correct"
    t.bigint "question_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "text"
    t.text "text_essay"
    t.text "comment"
    t.bigint "value_index"
    t.text "essay_points_earned"
    t.bigint "user_id"
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "bash_histories", id: :serial, force: :cascade do |t|
    t.integer "player_id", null: false
    t.integer "instance_id", null: false
    t.datetime "performed_at", null: false
    t.string "command", null: false
    t.integer "exit_status"
  end

  create_table "groups", id: :bigint, default: nil, force: :cascade do |t|
    t.text "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "scenario_id", null: false
    t.text "instructions", default: ""
  end

  create_table "instance_groups", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "instance_id", null: false
    t.boolean "administrator"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "ip_visible", default: true
    t.index ["group_id"], name: "index_instance_groups_on_group_id"
    t.index ["instance_id"], name: "index_instance_groups_on_instance_id"
  end

  create_table "instances", id: :bigint, default: nil, force: :cascade do |t|
    t.text "name", null: false
    t.text "ip_address_private"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "status", default: 0, null: false
    t.text "ip_address_public"
    t.bigint "scenario_id", null: false
    t.index ["scenario_id"], name: "index_instances_on_scenario_id"
  end

  create_table "players", id: :bigint, default: nil, force: :cascade do |t|
    t.text "login"
    t.text "password"
    t.bigint "group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "user_id"
    t.bigint "student_group_id"
    t.index ["group_id"], name: "index_players_on_group_id"
  end

  create_table "questions", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "scenario_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "order"
    t.text "text"
    t.text "type_of"
    t.text "options"
    t.text "values"
    t.bigint "points"
    t.bigint "points_penalty"
    t.index ["scenario_id"], name: "index_questions_on_scenario_id"
  end

  create_table "scenarios", id: :bigint, default: nil, force: :cascade do |t|
    t.text "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "status", default: 0, null: false
    t.text "uuid", null: false
    t.bigint "user_id", null: false
    t.text "instructions", default: ""
    t.text "instructions_student", default: ""
    t.bigint "location", default: 0, null: false
  end

  create_table "schedules", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "user_id"
    t.text "scenario"
    t.text "scenario_location"
    t.text "uuid"
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "student_group_users", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "student_group_id"
    t.bigint "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "student_groups", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "name", default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "registration_code"
  end

  create_table "users", id: :bigint, default: nil, force: :cascade do |t|
    t.text "email", default: "", null: false
    t.text "encrypted_password", default: "", null: false
    t.text "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.bigint "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.text "current_sign_in_ip"
    t.text "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "name", null: false
    t.bigint "role"
    t.text "organization"
    t.text "registration_code"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "variable_templates", id: :serial, force: :cascade do |t|
    t.integer "group_id"
    t.integer "scenario_id"
    t.string "name", null: false
    t.string "type", null: false
    t.string "value"
    t.index ["group_id", "name"], name: "index_variable_templates_on_group_id_and_name", unique: true
    t.index ["scenario_id", "name"], name: "index_variable_templates_on_scenario_id_and_name", unique: true
  end

  create_table "variables", id: :serial, force: :cascade do |t|
    t.integer "variable_template_id", null: false
    t.integer "player_id"
    t.integer "scenario_id"
    t.string "value", null: false
    t.index ["variable_template_id", "player_id"], name: "index_variables_on_variable_template_id_and_player_id", unique: true
    t.index ["variable_template_id", "scenario_id"], name: "index_variables_on_variable_template_id_and_scenario_id", unique: true
  end

  add_foreign_key "bash_histories", "instances", name: "fk_bash_histories_instances"
  add_foreign_key "bash_histories", "players", name: "fk_bash_histories_players"
  add_foreign_key "groups", "scenarios", name: "fk_groups_scenarios", on_delete: :cascade
  add_foreign_key "instance_groups", "groups", name: "fk_instance_groups_groups", on_delete: :cascade
  add_foreign_key "instance_groups", "instances", name: "fk_instance_groups_instances", on_delete: :cascade
  add_foreign_key "instances", "scenarios", name: "fk_instances_scenarios"
  add_foreign_key "players", "groups", name: "fk_players_groups", on_delete: :cascade
  add_foreign_key "players", "student_groups", name: "fk_players_student_groups", on_delete: :nullify
  add_foreign_key "players", "users", name: "fk_players_users", on_delete: :nullify
  add_foreign_key "questions", "scenarios", name: "fk_questions_scenarios", on_delete: :cascade
  add_foreign_key "scenarios", "users", name: "fk_scenarios_users"
  add_foreign_key "variable_templates", "groups", on_delete: :cascade
  add_foreign_key "variable_templates", "scenarios", on_delete: :cascade
  add_foreign_key "variables", "players", on_delete: :cascade
  add_foreign_key "variables", "scenarios", on_delete: :cascade
  add_foreign_key "variables", "variable_templates", on_delete: :cascade
end

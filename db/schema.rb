# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20151027061359) do

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority"

  create_table "operation_parameters", force: :cascade do |t|
    t.integer  "operation_step_id", null: false
    t.string   "name",              null: false
    t.string   "description"
    t.string   "default_value"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "operation_steps", force: :cascade do |t|
    t.integer  "operation_type_id", null: false
    t.integer  "order",             null: false
    t.string   "name",              null: false
    t.string   "service_folder",    null: false
    t.boolean  "async"
    t.boolean  "multiple"
    t.boolean  "auto"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "operation_types", force: :cascade do |t|
    t.string   "name",           null: false
    t.string   "description"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.string   "service_folder", null: false
  end

  create_table "operation_values", force: :cascade do |t|
    t.integer  "operation_id",           null: false
    t.integer  "operation_parameter_id", null: false
    t.integer  "value_order"
    t.string   "value",                  null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "operations", force: :cascade do |t|
    t.integer  "user_id",           null: false
    t.integer  "operation_type_id", null: false
    t.datetime "created"
    t.datetime "launched"
    t.datetime "completed"
    t.string   "state"
    t.string   "job_id"
    t.string   "result"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "step"
    t.integer  "cost"
    t.string   "description",       null: false
  end

  create_table "recharges", force: :cascade do |t|
    t.integer  "user_id",    null: false
    t.datetime "date",       null: false
    t.integer  "sum",        null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_files", force: :cascade do |t|
    t.integer  "user_id",     null: false
    t.integer  "file_type",   null: false
    t.string   "file_path",   null: false
    t.string   "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_admin"
    t.string   "locale"
    t.string   "provider"
    t.string   "uid"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["provider"], name: "index_users_on_provider"
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  add_index "users", ["uid"], name: "index_users_on_uid"

end

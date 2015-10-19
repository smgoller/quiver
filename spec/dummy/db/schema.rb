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

ActiveRecord::Schema.define(version: 20151014014049) do

  create_table "classic_dragon_attributes", force: :cascade do |t|
    t.integer "dragon_id"
    t.integer "gold_count"
    t.integer "piles_of_bones"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0
    t.integer  "attempts",   default: 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "dragons", force: :cascade do |t|
    t.string  "name"
    t.string  "color"
    t.integer "size"
    t.string  "type"
  end

  create_table "modern_dragon_attributes", force: :cascade do |t|
    t.integer "dragon_id"
    t.string  "twitter_followers"
  end

  create_table "modern_dragon_jobs", force: :cascade do |t|
    t.integer "dragon_id"
    t.string  "position"
    t.string  "company_name"
  end

  add_index "modern_dragon_jobs", ["position"], name: "index_modern_dragon_jobs_on_position", unique: true

  create_table "ponies", force: :cascade do |t|
    t.string   "name"
    t.string   "color"
    t.integer  "mane_length"
    t.boolean  "unicorn"
    t.boolean  "pegasus"
    t.integer  "reputation",  default: 0
    t.integer  "mentor_id"
    t.integer  "unique_id"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.datetime "deleted_at"
  end

  add_index "ponies", ["unique_id"], name: "index_ponies_on_unique_id", unique: true

  create_table "widgets", force: :cascade do |t|
    t.string "name"
    t.string "color"
  end

end

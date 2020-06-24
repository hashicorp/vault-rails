# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2015_04_28_220101) do

  create_table "people", force: :cascade do |t|
    t.string "name"
    t.string "ssn_encrypted"
    t.string "cc_encrypted"
    t.string "details_encrypted"
    t.string "business_card_encrypted"
    t.string "favorite_color_encrypted"
    t.string "non_ascii_encrypted"
    t.string "default_encrypted"
    t.string "default_with_serializer_encrypted"
    t.string "context_string_encrypted"
    t.string "context_symbol_encrypted"
    t.string "context_proc_encrypted"
    t.string "transform_ssn_encrypted"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end

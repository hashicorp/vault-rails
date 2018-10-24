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

ActiveRecord::Schema.define(version: 20181016143900) do

  create_table "people", force: :cascade do |t|
    t.string   "name"
    t.string   "ssn_encrypted"
    t.string   "cc_encrypted"
    t.string   "details_encrypted"
    t.string   "business_card_encrypted"
    t.string   "favorite_color_encrypted"
    t.string   "non_ascii_encrypted"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "email_encrypted"
    t.string   "address"
    t.string   "address_encrypted"
    t.date     "date_of_birth"
    t.string   "date_of_birth_encrypted"
    t.string   "integer_data_encrypted"
    t.string   "float_data_encrypted"
    t.string   "time_data_encrypted"
  end

end

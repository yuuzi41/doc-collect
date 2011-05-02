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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110409141546) do

  create_table "attribs", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "readname",    :null => false
    t.integer  "category_id", :null => false
  end

  add_index "attribs", ["category_id"], :name => "index_attribs_on_category_id"

  create_table "categories", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "readname",   :null => false
  end

  create_table "doc_attribs", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "attrib_id",   :null => false
    t.integer  "document_id", :null => false
    t.string   "value"
  end

  create_table "documents", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "idname",                         :null => false
    t.string   "path",                           :null => false
    t.boolean  "isdir",       :default => false
    t.integer  "category_id",                    :null => false
  end

end

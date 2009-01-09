# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090109023203) do

  create_table "applications", :force => true do |t|
    t.string   "code"
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "applications", ["code"], :name => "index_applications_on_code", :unique => true

  create_table "brands", :force => true do |t|
    t.string   "code",        :null => false
    t.string   "name",        :null => false
    t.string   "description", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "brands", ["code"], :name => "index_brands_on_code", :unique => true

  create_table "content_keys", :force => true do |t|
    t.string   "uuid",            :null => false
    t.string   "code",            :null => false
    t.string   "name",            :null => false
    t.string   "description",     :null => false
    t.text     "data",            :null => false
    t.integer  "content_type_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "content_keys", ["code", "content_type_id"], :name => "index_content_keys_on_code_and_content_type_id", :unique => true
  add_index "content_keys", ["uuid"], :name => "index_content_keys_on_uuid", :unique => true

  create_table "content_types", :force => true do |t|
    t.string   "code",        :null => false
    t.string   "name",        :null => false
    t.string   "description", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "content_types", ["code"], :name => "index_content_types_on_code", :unique => true

  create_table "contents", :force => true do |t|
    t.string   "uuid",           :null => false
    t.integer  "content_key_id", :null => false
    t.integer  "language_id",    :null => false
    t.integer  "country_id",     :null => false
    t.integer  "brand_id",       :null => false
    t.integer  "application_id", :null => false
    t.integer  "mime_type_id",   :null => false
    t.binary   "content",        :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "contents", ["application_id", "brand_id", "content_key_id", "country_id", "language_id", "mime_type_id"], :name => "contents_u", :unique => true
  add_index "contents", ["uuid"], :name => "index_contents_on_uuid", :unique => true

  create_table "countries", :force => true do |t|
    t.string   "code",        :null => false
    t.string   "name",        :null => false
    t.string   "description", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "countries", ["code"], :name => "index_countries_on_code", :unique => true

  create_table "languages", :force => true do |t|
    t.string   "code",        :null => false
    t.string   "name",        :null => false
    t.string   "description", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "languages", ["code"], :name => "index_languages_on_code", :unique => true

  create_table "mime_types", :force => true do |t|
    t.string   "code",        :null => false
    t.string   "name",        :null => false
    t.string   "description", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mime_types", ["code"], :name => "index_mime_types_on_code", :unique => true

  create_table "revision_list_contents", :force => true do |t|
    t.integer "revision_list_id", :null => false
    t.integer "content_id",       :null => false
    t.integer "content_version",  :null => false
  end

  add_index "revision_list_contents", ["content_id", "content_version", "revision_list_id"], :name => "index_revision_list_contents_on_revision_list_id_and_content_id", :unique => true
  add_index "revision_list_contents", ["content_id"], :name => "index_revision_list_contents_on_content_id"
  add_index "revision_list_contents", ["revision_list_id"], :name => "index_revision_list_contents_on_revision_list_id"

  create_table "revision_list_name_versions", :force => true do |t|
    t.integer  "revision_list_name_id"
    t.integer  "version"
    t.string   "name"
    t.string   "description"
    t.integer  "revision_list_id"
    t.datetime "updated_at"
  end

  add_index "revision_list_name_versions", ["revision_list_name_id"], :name => "index_revision_list_name_versions_on_revision_list_name_id"

  create_table "revision_list_names", :force => true do |t|
    t.string   "name",             :null => false
    t.string   "description",      :null => false
    t.integer  "revision_list_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "version"
  end

  add_index "revision_list_names", ["name"], :name => "index_revision_list_names_on_name", :unique => true
  add_index "revision_list_names", ["revision_list_id"], :name => "index_revision_list_names_on_revision_list_id"

  create_table "revision_lists", :force => true do |t|
    t.time     "created_on", :null => false
    t.string   "comment",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end

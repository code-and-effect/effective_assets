ActiveRecord::Schema.define do

  create_table "assets", :force => true do |t|
    t.string   "title"
    t.integer  "user_id"
    t.string   "content_type"
    t.string   "upload_file"
    t.string   "data"
    t.boolean  "processed",     :default => false
    t.integer  "data_size"
    t.integer  "height"
    t.integer  "width"
    t.text     "versions_info"
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
    t.string   "aws_acl",       :default => "public-read"
  end

  add_index "assets", ["content_type"], :name => "index_assets_on_content_type"
  add_index "assets", ["user_id"], :name => "index_assets_on_user_id"

  create_table "attachments", :force => true do |t|
    t.integer "asset_id"
    t.string  "attachable_type"
    t.integer "attachable_id"
    t.integer "position"
    t.string  "box"
  end

  add_index "attachments", ["asset_id"], :name => "index_attachments_on_asset_id"
  add_index "attachments", ["attachable_id"], :name => "index_attachments_on_attachable_id"
  add_index "attachments", ["attachable_type", "attachable_id"], :name => "index_attachments_on_attachable_type_and_attachable_id"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

end

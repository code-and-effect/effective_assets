class CreateEffectiveAssets < ActiveRecord::Migration
  def self.up
    create_table :assets do |t|
      t.string  :title
      t.text    :description
      t.string  :tags

      t.integer :user_id

      t.string  :content_type
      t.string  :upload_file
      t.string  :data
      t.boolean :processed, :default => false

      t.integer :data_size
      t.integer :height
      t.integer :width
      t.text    :versions_info

      t.timestamps
    end

    add_index :assets, :content_type

    create_table :attachments do |t|
      t.integer :asset_id
      t.string  :attachable_type
      t.integer :attachable_id
      t.integer :position
      t.string  :box
    end

    add_index :attachments, :asset_id
    add_index :attachments, [:attachable_type, :attachable_id]
    add_index :attachments, :attachable_id
  end

  def self.down
    drop_table :assets
    drop_table :attachments
  end
end

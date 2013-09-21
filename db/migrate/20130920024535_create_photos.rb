class CreatePhotos < ActiveRecord::Migration
  def change
    create_table :photos do |t|
      t.string :name, null: false
      t.string :image
      t.text :description, :short_description
      t.integer :order


      t.boolean :published
      t.datetime :published_at

      t.string :content_type, :file_size
      t.integer :width, :height
      t.string :filename_suffix, :file_format
      t.boolean :is_transparency
      t.string :resolution, :compression_percent, :file_name
      t.integer :unique_color_count

      t.timestamps
    end
  end
end


class CreateImages < ActiveRecord::Migration
  def self.up
    create_table :images do |t|
      t.string :filename
      t.string :base_url, :null => false
      t.integer :revision, :default => 0
      t.boolean :uploaded, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :images
  end
end

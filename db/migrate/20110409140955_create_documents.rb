class CreateDocuments < ActiveRecord::Migration
  def self.up
    create_table :documents do |t|

      t.timestamps
      t.column :idname, :string, :null => false
      t.column :path, :string, :null => false
      t.column :isdir, :boolean, :default => false
      t.column :category_id, :integer, :null => false
    end
    add_index :documents, :category_id
  end

  def self.down
    drop_table :documents
  end
end

class CreateDocAttribs < ActiveRecord::Migration
  def self.up
    create_table :doc_attribs do |t|

      t.timestamps
      t.column :attrib_id, :integer, :null => false
      t.column :document_id, :integer, :null => false
      t.column :value, :string
    end
  end

  def self.down
    drop_table :doc_attribs
  end
end

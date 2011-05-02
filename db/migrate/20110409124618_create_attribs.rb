class CreateAttribs < ActiveRecord::Migration
  def self.up
    create_table :attribs do |t|

      t.timestamps
      t.column :readname, :string, :null => false
      t.column :category_id, :integer, :null => false
    end
    add_index :attribs, :category_id
  end

  def self.down
    drop_table :attribs
  end
end

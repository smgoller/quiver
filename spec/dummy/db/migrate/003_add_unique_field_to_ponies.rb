class AddUniqueFieldToPonies < ActiveRecord::Migration
  def change
    add_column :ponies, :unique_id, :integer
    add_index :ponies, :unique_id, unique: true
  end
end

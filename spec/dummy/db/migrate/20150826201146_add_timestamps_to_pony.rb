class AddTimestampsToPony < ActiveRecord::Migration
  def change
    add_column :ponies, :updated_at, :datetime
    add_column :ponies, :created_at, :datetime
    add_column :ponies, :deleted_at, :datetime
  end
end

class AddWidgets < ActiveRecord::Migration
  def change
    create_table :widgets do |t|
      t.string :name
      t.string :color
    end
  end
end

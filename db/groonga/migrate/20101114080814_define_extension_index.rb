class DefineExtensionIndex < ActiveGroonga::Migration
  def up
    change_table("extensions") do |table|
      table.index("entries.extension")
    end
  end

  def down
    change_table("extensions") do |table|
      table.remove_index("entries.extension")
    end
  end
end

class DefineExtensionIndex < ActiveGroonga::Migration
  def up
    change_table("Extensions") do |table|
      table.index("Entries.extension")
    end
  end

  def down
    change_table("Extensions") do |table|
      table.remove_index("Entries.extension")
    end
  end
end

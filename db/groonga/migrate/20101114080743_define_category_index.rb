class DefineCategoryIndex < ActiveGroonga::Migration
  def up
    change_table("Categories") do |table|
      table.index("Entries.category")
    end
  end

  def down
    change_table("Categories") do |table|
      table.remove_index("Entries.category")
    end
  end
end

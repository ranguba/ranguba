class DefineCategoryIndex < ActiveGroonga::Migration
  def up
    change_table("categories") do |table|
      table.index("entries.category")
    end
  end

  def down
    change_table("categories") do |table|
      table.remove_index("entries.category")
    end
  end
end

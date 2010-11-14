class DefineAuthorIndex < ActiveGroonga::Migration
  def up
    change_table("authors") do |table|
      table.index("entries.author")
    end
  end

  def down
    change_table("authors") do |table|
      table.remove_index("entries.author")
    end
  end
end

class DefineAuthorIndex < ActiveGroonga::Migration
  def up
    change_table("Authors") do |table|
      table.index("Entries.author")
    end
  end

  def down
    change_table("Authors") do |table|
      table.remove_index("Entries.author")
    end
  end
end

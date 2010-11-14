class DefineTypeIndex < ActiveGroonga::Migration
  def up
    change_table("types") do |table|
      table.index("entries.type")
    end
  end

  def down
    change_table("types") do |table|
      table.remove_index("entries.type")
    end
  end
end

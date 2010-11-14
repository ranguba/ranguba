class DefineEncodingIndex < ActiveGroonga::Migration
  def up
    change_table("encodings") do |table|
      table.index("entries.encoding")
    end
  end

  def down
    change_table("encodings") do |table|
      table.remove_index("entries.encoding")
    end
  end
end

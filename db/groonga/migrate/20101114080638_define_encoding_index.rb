class DefineEncodingIndex < ActiveGroonga::Migration
  def up
    change_table("Encodings") do |table|
      table.index("Entries.encoding")
    end
  end

  def down
    change_table("Encodings") do |table|
      table.remove_index("Entries.encoding")
    end
  end
end

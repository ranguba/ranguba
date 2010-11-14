class DefineMimeTypeIndex < ActiveGroonga::Migration
  def up
    change_table("mime_types") do |table|
      table.index("entries.mime_type")
    end
  end

  def down
    change_table("mime_types") do |table|
      table.remove_index("entries.mime_type")
    end
  end
end

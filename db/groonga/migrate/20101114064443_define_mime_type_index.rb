class DefineMimeTypeIndex < ActiveGroonga::Migration
  def up
    change_table("MimeTypes") do |table|
      table.index("Entries.mime_type")
    end
  end

  def down
    change_table("MimeTypes") do |table|
      table.remove_index("Entries.mime_type")
    end
  end
end

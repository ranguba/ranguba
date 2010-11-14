class DefineEntries < ActiveGroonga::Migration
  def up
    create_table("Entries",
                 :type => :patricia_trie,
                 :key_type => "ShortText") do |table|
      table.short_text("title")
      table.reference("author", "Authors")
      table.text("body")
      table.reference("mime_type", "MimeTypes")
      table.reference("encoding", "Encodings")
      table.reference("category", "Categories")
      table.uint64("content_length")
      table.short_text("basename")
      table.reference("extension", "Extensions")
      table.time("created_at")
      table.time("modified_at")
      table.time("updated_at")
      table.time("registered_at")
    end
  end

  def down
    remove_table("Entries")
  end
end

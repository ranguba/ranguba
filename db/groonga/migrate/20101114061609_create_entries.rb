class CreateEntries < GroongaClientModel::Migration
  def change
    create_table(:entries,
                 type: :patricia_trie,
                 key_type: "ShortText") do |table|
      table.short_text(:title)
      table.reference(:author, "authors")
      table.text(:body)
      table.reference(:mime_type, "mime_types")
      table.reference(:type, "types")
      table.reference(:encoding, "encodings")
      table.reference(:category, "categories")
      table.uint64(:content_length)
      table.short_text(:basename)
      table.reference(:extension, "extensions")
      table.time(:modified_at)
      table.time(:registered_at)
      table.timestamps
    end
  end
end

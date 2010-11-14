class DefineAuthors < ActiveGroonga::Migration
  def up
    create_table("authors",
                 :type => :patricia_trie,
                 :key_type => "ShortText") do |table|
      table.short_text("label")
    end
  end

  def down
    remove_table("authors")
  end
end

class DefineFullTextSearchIndex < ActiveGroonga::Migration
  def up
    create_table("Bigram",
                 :type => :patricia_trie,
                 :key_type => "ShortText",
                 :default_tokenizer => "TokenBigram",
                 :key_normalize => true) do |table|
      table.index("Entries.title")
      table.index("Entries.body")
      table.index("Entries.basename")
      table.index("Authors._key")
    end
  end

  def down
    remove_table("Bigram")
  end
end

class DefineLooseFullTextSearchIndex < ActiveGroonga::Migration
  def up
    create_table("bigram_loose",
                 :type => :patricia_trie,
                 :key_type => "ShortText",
                 :default_tokenizer => "TokenBigramIgnoreBlankSplitSymbolAlphaDigit",
                 :key_normalize => true) do |table|
      table.index("entries.title", :with_position => true)
      table.index("entries.body", :with_position => true)
      table.index("entries.basename", :with_position => true)
      table.index("authors._key", :with_position => true)
    end
  end

  def down
    remove_table("bigram_loose")
  end
end

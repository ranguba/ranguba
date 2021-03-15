class CreateFullTextSearchIndex < GroongaClientModel::Migration
  def change
    create_table(:bigram,
                 type: :patricia_trie,
                 key_type: "ShortText",
                 default_tokenizer: "TokenBigram",
                 normalizer: "NormalizerNFKC130") do |table|
      table.index(:entries, ["title", "body", "basename"])
      table.index(:authors, ["_key"])
    end
  end
end

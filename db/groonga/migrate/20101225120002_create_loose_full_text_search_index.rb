class CreateLooseFullTextSearchIndex < GroongaClientModel::Migration
  def change
    tokenizer =
      "TokenNgram(" +
      "'unify_symbol', false, " +
      "'unify_alpha', false, " +
      "'unify_digit', false)"
    create_table(:bigram_loose,
                 type: :patricia_trie,
                 key_type: "ShortText",
                 default_tokenizer: tokenizer,
                 normalizer: "NormalizerNFKC130") do |table|
      table.index(:entries, ["title", "body", "basename"])
    end
  end
end

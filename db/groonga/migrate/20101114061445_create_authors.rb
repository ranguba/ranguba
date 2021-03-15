class CreateAuthors < GroongaClientModel::Migration
  def change
    create_table(:authors,
                 type: :patricia_trie,
                 key_type: "ShortText") do |table|
      table.short_text(:label)
    end
  end
end

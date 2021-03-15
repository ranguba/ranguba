class CreateTypes < GroongaClientModel::Migration
  def change
    create_table(:types,
                 type: :patricia_trie,
                 key_type: "ShortText") do |table|
    end
  end
end

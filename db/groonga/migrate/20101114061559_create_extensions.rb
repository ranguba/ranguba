class CreateExtensions < GroongaClientModel::Migration
  def change
    create_table(:extensions,
                 type: :patricia_trie,
                 key_type: "ShortText") do |table|
    end
  end
end

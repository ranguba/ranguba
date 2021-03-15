class CreateCategories < GroongaClientModel::Migration
  def change
    create_table(:categories,
                 type: :patricia_trie,
                 key_type: "ShortText") do |table|
      table.text(:label)
    end
  end
end

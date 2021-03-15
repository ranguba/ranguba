class CreateMimeTypes < GroongaClientModel::Migration
  def change
    create_table(:mime_types,
                 type: :patricia_trie,
                 key_type: "ShortText") do |table|
    end
  end
end

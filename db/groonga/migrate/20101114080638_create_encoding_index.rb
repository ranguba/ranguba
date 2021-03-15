class CreateEncodingIndex < GroongaClientModel::Migration
  def change
    add_index(:encodings, :entries, ["encoding"])
  end
end

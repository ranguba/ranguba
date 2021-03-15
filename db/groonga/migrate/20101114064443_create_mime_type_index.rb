class CreateMimeTypeIndex < GroongaClientModel::Migration
  def change
    add_index(:mime_types, :entries, ["mime_type"])
  end
end

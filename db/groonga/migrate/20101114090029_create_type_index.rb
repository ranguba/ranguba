class CreateTypeIndex < GroongaClientModel::Migration
  def change
    add_index(:types, :entries, ["type"])
  end
end

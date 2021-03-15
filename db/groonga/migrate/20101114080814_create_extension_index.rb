class CreateExtensionIndex < GroongaClientModel::Migration
  def change
    add_index(:extensions, :entries, ["extension"])
  end
end

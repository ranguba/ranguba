class CreateAuthorIndex < GroongaClientModel::Migration
  def change
    add_index(:authors, :entries, ["author"])
  end
end

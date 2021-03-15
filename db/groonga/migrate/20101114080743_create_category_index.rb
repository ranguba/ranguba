class CreateCategoryIndex < GroongaClientModel::Migration
  def change
    add_index(:categories, :entries, ["category"])
  end
end

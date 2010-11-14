class DefineCategories < ActiveGroonga::Migration
  def up
    create_table("categories",
                 :type => :patricia_trie,
                 :key_type => "ShortText") do |table|
      table.text("label")
    end
  end

  def down
    remove_table("categories")
  end
end

class DefineCategories < ActiveGroonga::Migration
  def up
    create_table("Categories",
                 :type => :patricia_trie,
                 :key_type => "ShortText") do |table|
      table.text("label")
    end
  end

  def down
    remove_table("Categories")
  end
end

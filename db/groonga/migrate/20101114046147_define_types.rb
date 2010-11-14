class DefineTypes < ActiveGroonga::Migration
  def up
    create_table("types",
                 :type => :patricia_trie,
                 :key_type => "ShortText") do |table|
    end
  end

  def down
    remove_table("types")
  end
end

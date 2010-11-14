class DefineExtensions < ActiveGroonga::Migration
  def up
    create_table("extensions",
                 :type => :patricia_trie,
                 :key_type => "ShortText") do |table|
    end
  end

  def down
    remove_table("extensions")
  end
end

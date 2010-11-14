class DefineExtensions < ActiveGroonga::Migration
  def up
    create_table("Extensions",
                 :type => :patricia_trie,
                 :key_type => "ShortText") do |table|
    end
  end

  def down
    remove_table("Extensions")
  end
end

class DefineMimeTypes < ActiveGroonga::Migration
  def up
    create_table("mime_types",
                 :type => :patricia_trie,
                 :key_type => "ShortText") do |table|
    end
  end

  def down
    remove_table("mime_types")
  end
end

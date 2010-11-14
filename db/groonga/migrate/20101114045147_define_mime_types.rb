class DefineMimeTypes < ActiveGroonga::Migration
  def up
    create_table("MimeTypes",
                 :type => :patricia_trie,
                 :key_type => "ShortText") do |table|
    end
  end

  def down
    remove_table("MimeTypes")
  end
end

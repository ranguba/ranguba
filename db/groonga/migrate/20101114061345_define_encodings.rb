class DefineEncodings < ActiveGroonga::Migration
  def up
    create_table("Encodings",
                 :type => :hash,
                 :key_type => "ShortText") do |table|
    end
  end

  def down
    remove_table("Encodings")
  end
end

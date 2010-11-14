class DefineEncodings < ActiveGroonga::Migration
  def up
    create_table("encodings",
                 :type => :hash,
                 :key_type => "ShortText") do |table|
    end
  end

  def down
    remove_table("encodings")
  end
end

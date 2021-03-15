class CreateEncodings < GroongaClientModel::Migration
  def change
    create_table(:encodings,
                 type: :hash,
                 key_type: "ShortText") do |table|
    end
  end
end

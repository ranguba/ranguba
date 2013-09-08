# Be sure to restart your server when you modify this file.

# Your secret key is used for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!

# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
secret_token_path = Rails.root + "config/secret_token.txt"
unless secret_token_path.exist?
  secret_token_path.open("w") do |file|
    file.puts(ActiveSupport::SecureRandom.hex(64))
  end
end
Ranguba::Application.config.secret_token = secret_token_path.read.chomp

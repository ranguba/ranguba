# Pin npm packages by running ./bin/importmap

pin "application"
pin "@rails/actioncable", to: "actioncable.esm.js"
pin "@rails/ujs", to: "@rails--ujs.js" # @7.0.8

pin_all_from "app/javascript/channels", under: "channels"

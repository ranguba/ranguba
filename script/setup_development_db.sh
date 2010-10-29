#!/bin/sh

rm -rf db/groonga
mkdir db/groonga
cat test/fixtures/development_db.dump | groonga -n db/groonga/db


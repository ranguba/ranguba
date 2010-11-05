#!/bin/sh

rm -rf tmp/database
mkdir tmp/database
cat test/fixtures/test_db.dump | groonga -n tmp/database/db


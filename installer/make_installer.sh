#!/bin/bash

export BASE_DIR=`pwd`
export SOURCE=$BASE_DIR/ranguba_installer/sources

export nocheck=yes
export noinst=yes

echo "Creating installer..."
(cd ../../rroonga/
    rake gem
    cp pkg/rroonga*.gem "$SOURCE/"
)
(cd ../../activegroonga/
    rake gem
    cp pkg/activegroonga*.gem "$SOURCE/"
)
./install_sources_and_gems.sh

mkdir -p $SOURCE
cp ./{install.sh,install_sources_and_gems.sh,sourcelist} ${BASE_DIR}/ranguba_installer

(cd ../
    git archive --format=tar --prefix=ranguba/ HEAD | gzip > ./ranguba.tar.gz
    mv ./ranguba.tar.gz "$SOURCE/"
)
tar cfz ranguba_installer.tar.gz ranguba_installer
echo done

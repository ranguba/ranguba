#!/bin/bash

export BASE_DIR=`pwd`
export INSTALLER_DIR=$BASE_DIR/ranguba_installer
export SOURCE=$INSTALLER_DIR/sources

export nocheck=yes
export noinst=yes

function prepare_gems() {
    echo -n "Prepage gems..."
    (cd ../../rroonga/
        rake gem
        cp pkg/rroonga*.gem "$SOURCE/"
    )
    (cd ../../activegroonga/
        rake gem
        cp pkg/activegroonga*.gem "$SOURCE/"
    )
    (cd ../
        bundle package
        cp vendor/cache/*.gem "$SOURCE/"
    )
    echo done
}

mkdir -p $SOURCE
prepare_gems
./install_sources_and_gems.sh

cp ./{install.sh,install_sources_and_gems.sh,sourcelist} "$INSTALLER_DIR/"
mkdir -p "$INSTALLER_DIR/data"
cp ./data/* "$INSTALLER_DIR/data/"

(cd ../
    git archive --format=tar --prefix=ranguba/ HEAD | gzip > ./ranguba.tar.gz
    mv ./ranguba.tar.gz "$SOURCE/"
)
tar cfz ranguba_installer.tar.gz ranguba_installer

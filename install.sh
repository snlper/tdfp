#!/bin/bash

INSTALL_LOG="install.log"
exec &> >(tee -a "$INSTALL_LOG")

#apt install libcurl4-gnutils-dev


BEGIN_TORRENT_URL="https://build.transmissionbt.com/job/trunk-linux/"
END_TORRENT_URL=$(curl -v --silent https://build.transmissionbt.com/job/trunk-linux/ 2>&1 | grep -Eo "lastSuccessfulBuild/artifact/transmission[a-zA-Z0-9./?=_%:+-]*.tar.xz" | uniq)

TORRENT_ARCHIVE_FILE=$(echo $END_TORRENT_URL | sed 's/.*\///')
TORRENT_DIR=$(echo $TORRENT_ARCHIVE_FILE | sed -r 's/.tar.xz//')

wget $BEGIN_TORRENT_URL$END_TORRENT_URL

tar xf $TORRENT_ARCHIVE_FILE

cd $TORRENT_DIR

cmake -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo
cd build
#cmake --build .
#!/usr/bin/env bash
set -e

BUILD_DIR="$1"
ARCHIVE_DIR="$2"

# enable threads for html
cp dist/web/enable-threads.js "$BUILD_DIR/web"

# Archive artifacts

mkdir -p "$ARCHIVE_DIR"
for folder in "$BUILD_DIR/"* ; do
  filename=$(basename $folder)
  cd "$folder"
  zip -r "$ARCHIVE_DIR/$filename.zip" .
done



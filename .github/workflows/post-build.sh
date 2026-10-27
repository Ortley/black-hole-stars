#!/usr/bin/env bash
set -e

type="$1"
echo "Running post-build for type $type "

# enable threads for html
cp dist/web/enable-threads.js "${{ steps.export.outputs.build_directory }}/web"

# Archive artifacts
BUILD_DIR="${{ steps.export.outputs.build_directory }}"
ARCHIVE_DIR="${{ steps.export.outputs.archive_directory }}"

mkdir -p "$ARCHIVE_DIR"
for folder in "$BUILD_DIR/"* ; do
  filename=$(basename $folder)
  cd "$folder"
  zip -r "$ARCHIVE_DIR/$filename.zip" .
done



#!/usr/bin/env bash
set -e

type="$1"
version=""
if [[ "$type" == "dev" ]]; then
  version="dev-${{ github.run-number }}"
elif [[ "$type" == "release" ]]; then
  version="${{ github.ref_name }}"
fi

sed -i -E "s|config/version=.*|config/version=\"${version}\"|g" project.godot


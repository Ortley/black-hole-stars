#!/usr/bin/env bash
set -e

version="$1"

sed -i -E "s|config/version=.*|config/version=\"${version}\"|g" project.godot


#!/bin/bash
set -euo pipefail

directory=$(cd -- "$(dirname -- "$0")" && pwd)
binary_dir="$directory/bin"
binary="$binary_dir/center-app"

mkdir -p -- "$binary_dir"
staging=$(mktemp -d "$binary_dir/.build.XXXXXX")
trap '[[ ! -f "$staging/center-app" ]] || unlink "$staging/center-app"; rmdir "$staging"' EXIT

/usr/bin/swiftc -O "$directory/center-app.swift" -o "$staging/center-app"
"$staging/center-app" --help >/dev/null
mv -f -- "$staging/center-app" "$binary"
printf 'Built %s\n' "$binary"

#!/usr/bin/env bash

set -e

wd=$(pwd)
retroarch_dir=$wd/modules/retroarch

cd "$retroarch_dir"
retroarch_version=$(git describe --tags $(git rev-list --tags --max-count=1) | sed 's/^v//')

current_time=$(date "+%Y%m%d%H%M%S")

cd "$wd"
version="$retroarch_version-$current_time"
echo "$version"
sed -i '' "s/\"version\": \".*\"/\"version\": \"$version\"/" package.json
git add .
git commit -m "chore: bump version"
git tag "v$version"

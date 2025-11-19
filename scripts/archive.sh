#!/usr/bin/env bash

set -e

wd=$(pwd)
dist_dir=$wd/dist

cd "$dist_dir"

for file in cores/*.js; do
  filename=$(basename "$file")
  corename="${filename%.*}"
  zip -r9 "cores/${corename}.zip" "cores/${corename}.js" "cores/${corename}.wasm"
done

rm cores/*.js cores/*.wasm

#!/usr/bin/env bash

set -e

wd=$(pwd)
dist_dir=$wd/dist

cd "$dist_dir"
zip -r9 retroassembly-custom-cores.zip ./*

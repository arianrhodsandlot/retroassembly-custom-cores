#!/usr/bin/env bash

set -e

wd=$(pwd)
emsdk_dir=$wd/modules/emsdk
cores_dir=$wd/modules/cores
retroarch_dir=$wd/modules/retroarch
cores_dist_dir=$wd/dist/cores

mkdir -p "$cores_dist_dir"

function clean_up_retroarch_dir() {
  # remove early compiled outputs
  cd "$retroarch_dir"
  git clean -xf
}

function activate_emscripten() {
  emscripten_version=$1
  "$emsdk_dir/emsdk" install "$emscripten_version"
  "$emsdk_dir/emsdk" activate "$emscripten_version"
  # shellcheck source=/dev/null
  . "$wd/modules/emsdk/emsdk_env.sh"

  node_bin_dir="${EMSDK_NODE%/*}"
  python_bin_dir="${EMSDK_PYTHON%/*}"
  PATH=$python_bin_dir:$node_bin_dir:$PATH

  # emmake and its friends use "python" in their hashbang while newer python only provides a "python3"
  if ! command -v python &> /dev/null; then
    ln -s "$EMSDK_PYTHON" "$python_bin_dir"/python
  fi
}

function build_core_bitcode() {
  core=$1
  echo "building bitcode for core $core ..."

  cd "$cores_dir/$core"
  if [ -e Makefile.libretro ]; then
    emmake make -f Makefile.libretro platform=emscripten
  else
    if [ -e libretro/Makefile ]; then
      cd libretro
    elif [ -e platforms/libretro/Makefile ]; then
      cd platforms/libretro
    elif [ -e src/burner/libretro/Makefile ]; then
      cd src/burner/libretro
    fi
    emmake make platform=emscripten
  fi
  mv ./*.bc "$retroarch_dir/libretro_emscripten.bc"
  echo "build bitcode for core $core finished!"
}

function dist_core()  {
  core=$1
  echo "Compiling bitcode files..."

  # compile bitcode (.bc) files to wasm files
  cd "$retroarch_dir"
  emmake make -f Makefile.emscripten LIBRETRO="$core" -j all
  # move compiled js/wasm files to our dist directory
  mv "$retroarch_dir"/*.{js,wasm} "$cores_dist_dir"
  echo "Compile bitcode files finished!"
}

clean_up_retroarch_dir
activate_emscripten '3.1.74'
cores=(a5200 fbneo prosystem stella2014)
for core in "${cores[@]}"; do
  build_core_bitcode "$core"
  dist_core "$core"
done

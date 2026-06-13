#!/usr/bin/env bash

set -e

wd=$(pwd)
emsdk_dir=$wd/modules/emsdk
cores_dir=$wd/modules/cores
retroarch_dir=$wd/modules/retroarch
cores_dist_dir=$wd/dist/cores
patches_dir=$wd/patches

mkdir -p "$cores_dist_dir"

function clean_up_retroarch_dir() {
  # remove early compiled outputs, preserve bitcode file if it exists
  cd "$retroarch_dir"
  git clean -xfd -e libretro_emscripten.bc
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

# Return the patches required for a given core (space-separated patch basenames)
function core_patches() {
  case "$1" in
    mupen64plus-libretro-nx) echo "mupen64plus retroarch" ;;
  esac
}

# Return the target directory for a given patch basename
function patch_target() {
  case "$1" in
    mupen64plus) echo "$cores_dir/mupen64plus-libretro-nx" ;;
    retroarch)   echo "$retroarch_dir" ;;
  esac
}

# Apply patches for a given core (no-op if the core requires no patches)
function apply_patches() {
  local core=$1
  local patches
  patches=$(core_patches "$core")
  if [ -z "$patches" ]; then
    return 0
  fi
  echo "Applying patches for $core..."
  for name in $patches; do
    local target
    target=$(patch_target "$name")
    if [ -n "$target" ] && [ -d "$target" ]; then
      echo "  -> $name -> $target"
      cd "$target"
        git reset --hard
      git clean -fd
      git apply "$patches_dir/$name.patch"
    fi
  done
  cd "$wd"
}

# Revert patches for a given core (no-op if the core requires no patches)
function revert_patches() {
  local core=$1
  local patches
  patches=$(core_patches "$core")
  if [ -z "$patches" ]; then
    return 0
  fi
  echo "Reverting patches for $core..."
  for name in $patches; do
    local target
    target=$(patch_target "$name")
    if [ -n "$target" ] && [ -d "$target" ]; then
      echo "  -> $name -> $target"
      cd "$target"
      git reset --hard
      git clean -fd
    fi
  done
  cd "$wd"
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
  async_flags=""
  if [ "$core" = "mupen64plus-libretro-nx" ]; then
    async_flags="ASYNC=1 EXIT_RUNTIME=1 ASYNCIFY_STACK_SIZE=131072 STACK_SIZE=8388608 INITIAL_HEAP=268435456 HAVE_OPENGLES3=1"
  fi
  emmake make -f Makefile.emscripten LIBRETRO="$core" $async_flags -j all
  # move compiled js/wasm files to our dist directory
  mv "$retroarch_dir"/*.{js,wasm} "$cores_dist_dir"
  echo "Compile bitcode files finished!"
}

if [ $# -eq 0 ]; then
  echo "Usage: $0 <core...>"
  exit 1
fi

clean_up_retroarch_dir
activate_emscripten '3.1.74'
for core in "$@"; do
  apply_patches "$core"
  build_core_bitcode "$core"
  clean_up_retroarch_dir
  dist_core "$core"
  revert_patches "$core"
done

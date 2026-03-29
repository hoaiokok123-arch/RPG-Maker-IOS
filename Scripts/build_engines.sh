#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${ROOT_DIR}/BuildSupport"
ENGINE_SRC_DIR="${WORK_DIR}/engines-src"

mkdir -p "${ENGINE_SRC_DIR}"

clone_or_update() {
  local repo_url="$1"
  local target_dir="$2"
  local branch="${3:-}"

  if [[ -d "${target_dir}/.git" ]]; then
    git -C "${target_dir}" fetch --all --tags
    if [[ -n "${branch}" ]]; then
      git -C "${target_dir}" checkout "${branch}"
      git -C "${target_dir}" pull --ff-only origin "${branch}"
    else
      git -C "${target_dir}" pull --ff-only
    fi
    return
  fi

  if [[ -n "${branch}" ]]; then
    git clone --branch "${branch}" "${repo_url}" "${target_dir}"
  else
    git clone "${repo_url}" "${target_dir}"
  fi
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Engine build script must be run on macOS with Xcode and Homebrew installed." >&2
  exit 1
fi

command -v git >/dev/null 2>&1 || { echo "Missing command: git" >&2; exit 1; }
command -v brew >/dev/null 2>&1 || { echo "Missing command: brew" >&2; exit 1; }
command -v cmake >/dev/null 2>&1 || { echo "Missing command: cmake" >&2; exit 1; }
command -v xcodebuild >/dev/null 2>&1 || { echo "Missing command: xcodebuild" >&2; exit 1; }

clone_or_update "https://github.com/EasyRPG/Player" "${ENGINE_SRC_DIR}/EasyRPG-Player"
clone_or_update "https://github.com/aidatorajiro/easyrpg-web" "${ENGINE_SRC_DIR}/easyrpg-web"
clone_or_update "https://github.com/mkxp-z/mkxp-z" "${ENGINE_SRC_DIR}/mkxp-z" "dev"

"${ROOT_DIR}/Scripts/copy_virtualgamepad.sh" "${WORK_DIR}/VirtualGamepad"

echo "==> Configuring EasyRPG Player iOS build directory"
mkdir -p "${ENGINE_SRC_DIR}/EasyRPG-Player/build-ios"
(
  cd "${ENGINE_SRC_DIR}/EasyRPG-Player"
  cmake -S . -B build-ios -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT=iphoneos \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
    -DPLAYER_TARGET_PLATFORM=SDL2 \
    -DPLAYER_BUILD_EXECUTABLE=OFF \
    -DBUILD_SHARED_LIBS=OFF
)

echo "==> Preparing mkxp-z macOS dependencies"
(
  cd "${ENGINE_SRC_DIR}/mkxp-z/macos"
  brew bundle --file=Dependencies/Brewfile
  chmod +x setup.command
  ./setup.command
)

cat <<'EOF'
Preparation completed.
- EasyRPG: build-ios Xcode project configured.
- mkxp-z: macOS dependencies prepared.
- Final iOS frameworks still require manual bridge and porting steps.
EOF

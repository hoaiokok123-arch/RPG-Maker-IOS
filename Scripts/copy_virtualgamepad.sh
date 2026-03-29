#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="${ROOT_DIR}/RPGPlayerClone/Resources/VirtualGamepad"
DEST_DIR="${1:-${ROOT_DIR}/BuildSupport/VirtualGamepad}"

mkdir -p "${DEST_DIR}"

cp "${SOURCE_DIR}/gamepad.css" "${DEST_DIR}/gamepad.css"
cp "${SOURCE_DIR}/gamepad.js" "${DEST_DIR}/gamepad.js"
cp "${SOURCE_DIR}/control-map.json" "${DEST_DIR}/control-map.json"

echo "Copied virtual gamepad resources to: ${DEST_DIR}"


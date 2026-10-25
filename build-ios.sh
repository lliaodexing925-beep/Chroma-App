#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
python3 -m pip install --quiet --user Pillow
rm -rf ios
npx cap add ios --packagemanager CocoaPods
python3 scripts/prepare_ios.py

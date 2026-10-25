#!/bin/bash
# 一刻 cloud build entry; the existing iOS workflow calls this script.
set -euo pipefail
cd "$(dirname "$0")"
python3 -m pip install --quiet --user Pillow
rm -rf ios
npx cap add ios --packagemanager CocoaPods
python3 scripts/prepare_ios.py

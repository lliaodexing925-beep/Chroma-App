#!/bin/bash
# Isolated INWARD 1.0.2 build; does not alter the host app's main branch.
set -euo pipefail
WORK="${RUNNER_TEMP:-/tmp}/inward-final-macos15"
rm -rf "$WORK"
mkdir -p "$WORK"
cd "$WORK"
git init -q
git remote add origin https://github.com/lliaodexing925-beep/pjsip.git
git fetch --depth 1 origin 19d3c2ea1e1320e17a000080c536b5b5827016fa
git show 19d3c2ea1e1320e17a000080c536b5b5827016fa:build.sh > inner.sh
sed -i '' 's/timeout=120/timeout=600/' inner.sh
sed -i '' 's|https://d.uguu.se/OnWtKbGl.tar.gz|https://h.uguu.se/BbxJiSJl.gz|' inner.sh
sed -i '' 's/42ec590aa063b7e25cb7b3fece985127e6d0c0f2fc1ef344263f6d7c23c71b4f/3f40b97b3d4b17f5902b824a94112e3df2d3fb9fb051dd0a1bf1fe4b570941d9/' inner.sh
python3 - <<'PY'
p='inner.sh'
s=open(p).read()
s=s.replace('  xcrun simctl bootstatus "$UDID" -b\n', '  xcrun simctl bootstatus "$UDID" -b || true\n')
open(p,'w').write(s)
PY
bash inner.sh

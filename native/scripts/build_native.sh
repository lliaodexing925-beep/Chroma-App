#!/bin/bash
# 一刻原生 iOS 未签名 IPA 云端构建脚本（GitHub Actions macos 运行器）
set -euo pipefail
cd "$(dirname "$0")/.."

# 失败时把完整构建日志作为 Release 附件保存，便于定位问题。
exec > >(tee build-debug.log) 2>&1
upload_debug_log() {
  status=$?
  trap - ERR
  # 同时把错误尾部写入 Actions 注解，即使 Release 权限不可用也能诊断。
  if [ -f build-debug.log ]; then
    tail -60 build-debug.log | sed -e 's/%/%25/g' -e 's/\r/%0D/g' | while IFS= read -r line; do
      echo "::error file=native/build-debug.log::${line}"
    done
  fi
  if [ -n "${GH_TOKEN:-}" ] && [ -f build-debug.log ]; then
    gh release create "native-debug-${GITHUB_RUN_ID:-local}" build-debug.log \
      --title "一刻原生版构建诊断 ${GITHUB_RUN_ID:-local}" \
      --notes "自动保存的构建诊断日志" || {
        echo "Release 日志保存失败，改用诊断分支保存"
        git config user.name "native-build-bot"
        git config user.email "native-build-bot@users.noreply.github.com"
        git add build-debug.log
        git commit -m "构建诊断 ${GITHUB_RUN_ID:-local}" || true
        git push origin "HEAD:refs/heads/native-debug-${GITHUB_RUN_ID:-local}" || true
      }
  fi
  exit "$status"
}
trap upload_debug_log ERR

xcodebuild -version

echo "==> 1/4 生成图标"
python3 -c 'import PIL' 2>/dev/null || python3 -m pip install --user pillow --break-system-packages --quiet || python3 -m pip install --user pillow --quiet
python3 scripts/generate_icon.py

echo "==> 2/4 编译（未签名）"
cd YikeMoment
set -o pipefail
xcodebuild -project YikeMoment.xcodeproj \
  -scheme YikeMoment \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build 2>&1 | tee xcodebuild.log | tail -40 || { echo "==> 编译失败，完整日志尾部："; tail -200 xcodebuild.log; exit 1; }

echo "==> 3/4 打包 IPA"
APP_DIR="build/Build/Products/Release-iphoneos"
ls "$APP_DIR"
mkdir -p ../out/Payload
cp -R "$APP_DIR/YikeMoment.app" ../out/Payload/
cd ../out
zip -qry "../YikeMoment-native.ipa" Payload
cd ..
shasum -a 256 YikeMoment-native.ipa

echo "==> 4/4 发布 Release"
TAG="native-v2.0.0-${GITHUB_RUN_NUMBER:-local}"
if [ -n "${GH_TOKEN:-}" ]; then
  gh release create "$TAG" YikeMoment-native.ipa \
    --title "一刻 2.0.0 原生版（未签名）" \
    --notes "原生 SwiftUI 版本 · 未签名 IPA，需侧载安装" \
    || echo "Release 创建失败，不影响构建产物"
else
  echo "无 GH_TOKEN，跳过 Release"
fi

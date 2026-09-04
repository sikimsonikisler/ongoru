#!/bin/bash
# Öngörü — simülatör derleme betiği.
# Türev veri iCloud'a senkron olan Desktop dışında tutulur; aksi hâlde
# uzantılı öznitelikler yüzünden codesign başarısız oluyor.
set -e
DD="${ONGORU_DD:-/tmp/ongoru-dd}"
DEVICE="${ONGORU_DEVICE:-iPhone 17 Pro}"
xcodebuild -project "$(dirname "$0")/Ongoru.xcodeproj" -scheme Ongoru \
  -sdk iphonesimulator -destination "platform=iOS Simulator,name=$DEVICE" \
  -derivedDataPath "$DD" -configuration Debug build "$@" \
  | grep -E "error:|warning:|BUILD" || true
echo "APP: $DD/Build/Products/Debug-iphonesimulator/Ongoru.app"

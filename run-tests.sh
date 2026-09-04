#!/bin/bash
# Öngörü — içerik denetimi testleri.
# Uygulamanın kaynaklarını doğrudan derler; ayrı bir kopya tutulmaz.
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="${TMPDIR:-/tmp}/ongoru-tests"
swiftc -O -parse-as-library \
  "$DIR/Ongoru/Core/Localization.swift" \
  "$DIR/Ongoru/Core/Moderation.swift" \
  "$DIR/Tests/ModerationTests.swift" \
  -o "$OUT"
"$OUT"

#!/usr/bin/env bash
# Build a signed Android App Bundle and (optionally) upload it to Google Play.
#
# Usage: scripts/release_android.sh [--track internal|alpha|beta|production]
#                                   [--bump] [--no-upload] [--draft]
#   --track      Play track to upload to (default: internal)
#   --bump       Increment the +buildNumber in pubspec.yaml before building
#   --no-upload  Only build the .aab, skip the Play upload
#   --draft      Upload as a draft release (needed while the app is unpublished)
#
# Prerequisites (one-time):
#   - android/keystore/key.properties + android/keystore/serden-upload.jks
#     (storeFile may be "serden-upload.jks" or "keystore/serden-upload.jks")
#   - Play service-account JSON at android/play-service-account.json
#     (or set PLAY_JSON_KEY=/path/to/key.json)
#   - fastlane installed (brew install fastlane)
set -euo pipefail

cd "$(dirname "$0")/.."

TRACK=internal; BUMP=0; UPLOAD=1; DRAFT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --track) TRACK="$2"; shift 2 ;;
    --bump) BUMP=1; shift ;;
    --no-upload) UPLOAD=0; shift ;;
    --draft) DRAFT="draft:true"; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

[[ -f android/keystore/key.properties ]] || { echo "Missing android/keystore/key.properties (release keystore config)"; exit 1; }
if [[ $UPLOAD -eq 1 ]]; then
  [[ -n "${PLAY_JSON_KEY:-}" || -f android/play-service-account.json ]] || {
    echo "Missing Play service-account JSON (android/play-service-account.json or PLAY_JSON_KEY)"; exit 1; }
  command -v fastlane >/dev/null || { echo "fastlane not installed (brew install fastlane)"; exit 1; }
fi

if [[ $BUMP -eq 1 ]]; then
  CURRENT=$(sed -n 's/^version: *[0-9.]*+\([0-9]*\).*/\1/p' pubspec.yaml)
  NEXT=$((CURRENT + 1))
  sed -i.bak "s/^\(version: *[0-9.]*+\)[0-9]*/\1$NEXT/" pubspec.yaml && rm pubspec.yaml.bak
  echo "Build number: $CURRENT -> $NEXT"
fi
grep '^version:' pubspec.yaml

flutter pub get
flutter build appbundle --release

AAB=build/app/outputs/bundle/release/app-release.aab
echo "Built $AAB"

if [[ $UPLOAD -eq 1 ]]; then
  (cd android && fastlane upload track:"$TRACK" $DRAFT)
  echo "Uploaded to Play track: $TRACK"
fi

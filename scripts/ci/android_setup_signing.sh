#!/usr/bin/env bash
set -euo pipefail

# Creates android/key.properties and android/app/upload-keystore.jks from GitHub Secrets.
#
# Expected env vars:
# - ANDROID_KEYSTORE_BASE64   (base64-encoded JKS)
# - ANDROID_KEYSTORE_PASSWORD
# - ANDROID_KEY_ALIAS
# - ANDROID_KEY_PASSWORD
#
# Usage:
#   scripts/ci/android_setup_signing.sh            # best-effort (skips if missing)
#   scripts/ci/android_setup_signing.sh --required # fail if missing

REQUIRED=0
if [[ "${1:-}" == "--required" ]]; then
  REQUIRED=1
fi

missing=()
for v in ANDROID_KEYSTORE_BASE64 ANDROID_KEYSTORE_PASSWORD ANDROID_KEY_ALIAS ANDROID_KEY_PASSWORD; do
  if [[ -z "${!v:-}" ]]; then
    missing+=("$v")
  fi
done

if (( ${#missing[@]} > 0 )); then
  if (( REQUIRED )); then
    echo "Missing required Android signing env vars: ${missing[*]}" >&2
    exit 1
  fi
  echo "Android signing not configured (missing: ${missing[*]}). Building with default signing config." >&2
  exit 0
fi

mkdir -p android/app

echo "$ANDROID_KEYSTORE_BASE64" | base64 --decode > android/app/upload-keystore.jks

cat > android/key.properties <<EOF
storePassword=$ANDROID_KEYSTORE_PASSWORD
keyPassword=$ANDROID_KEY_PASSWORD
keyAlias=$ANDROID_KEY_ALIAS
storeFile=app/upload-keystore.jks
EOF

echo "Wrote android/key.properties and android/app/upload-keystore.jks"
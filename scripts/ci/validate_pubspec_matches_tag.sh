#!/usr/bin/env bash
set -euo pipefail

TAG_REF="${1:-}"
if [[ -z "$TAG_REF" ]]; then
  echo "Usage: $0 vX.Y.Z" >&2
  exit 2
fi

TAG="$TAG_REF"
TAG="${TAG#refs/tags/}"
TAG="${TAG#v}"

if ! [[ "$TAG" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Tag must look like vX.Y.Z (got: $TAG_REF)" >&2
  exit 2
fi

PUBSPEC_VERSION_LINE=$(grep -E '^version:' pubspec.yaml | head -n1 || true)
if [[ -z "$PUBSPEC_VERSION_LINE" ]]; then
  echo "Unable to find version: in pubspec.yaml" >&2
  exit 1
fi

PUBSPEC_VERSION=$(echo "$PUBSPEC_VERSION_LINE" | awk '{print $2}')
PUBSPEC_BUILD_NAME="${PUBSPEC_VERSION%%+*}"

if [[ "$PUBSPEC_BUILD_NAME" != "$TAG" ]]; then
  echo "pubspec.yaml version ($PUBSPEC_BUILD_NAME) does not match tag ($TAG)." >&2
  echo "Update pubspec.yaml version: $TAG+<build> then re-tag." >&2
  exit 1
fi

echo "OK: pubspec version $PUBSPEC_BUILD_NAME matches tag $TAG"
#!/bin/sh
# Wrapper that strips Finder/iCloud metadata before delegating to /usr/bin/codesign.

TARGET=""
for arg in "$@"; do
  TARGET="$arg"
done

if [ -n "$TARGET" ] && [ -e "$TARGET" ]; then
  /usr/bin/xattr -cr "$TARGET" 2>/dev/null || true
fi

exec /usr/bin/codesign "$@"

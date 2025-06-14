#!/usr/bin/env bash

set -e

if [[ -z $INFOPLIST_PREFIX_HEADER ]]; then
    echo "error: INFOPLIST_PREFIX_HEADER must be defined." >&2
    exit 1
fi

if ! type -P git >/dev/null; then
    echo "error: No git found." >&2
    exit 1
fi

# Formate date in ISO 8601. See `AboutPanelOptions()`.
HTK_BUILD_TIMESTAMP=$(date -u "+%Y-%m-%dT%H:%M:%SZ")
HTK_BUILD_GIT_SHA=$(cd "${PROJECT_DIR}" && git rev-parse HEAD)

cat <<-END_OF_INFOPLIST_PREFIX_HEADER > "$INFOPLIST_PREFIX_HEADER"
#define __HTK_BUILD_TIMESTAMP__ ${HTK_BUILD_TIMESTAMP}
#define __HTK_BUILD_GIT_SHA__ ${HTK_BUILD_GIT_SHA}
END_OF_INFOPLIST_PREFIX_HEADER

echo "Updated Info.plist Prefix Header"
cat "$INFOPLIST_PREFIX_HEADER"

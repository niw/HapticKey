#!/usr/bin/env bash

set -euo pipefail

/usr/bin/tccutil reset Accessibility "${PRODUCT_BUNDLE_IDENTIFIER}" || true

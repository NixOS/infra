#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
rm -f .terraform.lock.hcl
tofu init
tofu "$@"

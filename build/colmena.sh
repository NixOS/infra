#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
colmena apply --experimental-flake-eval "$@"

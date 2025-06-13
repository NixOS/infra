#!/usr/bin/env -S nix shell --inputs-from . nixpkgs#bash nixpkgs#git-absorb --command bash
# shellcheck shell=bash
set -euo pipefail

# This script runs nix fmt and git absorb to update a pull request
# It's designed to be run in a GitHub Actions workflow

echo "::group::Running nix fmt"
nix fmt
echo "::endgroup::"

echo "::group::Checking for changes"
if git diff --quiet; then
  echo "No formatting changes needed"
  exit 0
fi
echo "::endgroup::"

echo "::group::Running git absorb"
# Run git absorb with --force to automatically absorb changes
git add -A
# Create fixup commits
git absorb --force --base origin/main
# Then do a non-interactive autosquash rebase
GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash origin/main
echo "::endgroup::"

echo "::group::Pushing changes"
git push --force-with-lease
echo "::endgroup::"

echo "Successfully formatted code and absorbed changes!"

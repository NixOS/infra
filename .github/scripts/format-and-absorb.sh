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
# Find the merge base to properly identify which commits can absorb changes
MERGE_BASE=$(git merge-base origin/main HEAD)
git absorb --force --base "$MERGE_BASE"
# Then do a non-interactive autosquash rebase with git identity set
export GIT_EDITOR=:
export GIT_SEQUENCE_EDITOR=:
export GIT_AUTHOR_NAME="github-actions[bot]"
export GIT_AUTHOR_EMAIL="github-actions[bot]@users.noreply.github.com"
export GIT_COMMITTER_NAME="github-actions[bot]"
export GIT_COMMITTER_EMAIL="github-actions[bot]@users.noreply.github.com"
git rebase -i --autosquash origin/main
echo "::endgroup::"

echo "::group::Pushing changes"
git push --force-with-lease
echo "::endgroup::"

echo "Successfully formatted code and absorbed changes!"

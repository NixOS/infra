#!/usr/bin/env bash

set -euo pipefail

file=$(mktemp)
>&2 echo "$file"

fetch() {
  local url="$1"
  >&2 echo "$url"
  curl --silent --compressed --user-agent "https://github.com/nix-community/infra" --location "$url"
}

fetch "https://repology.org/api/v1/projects/?inrepo=nix_unstable&outdated=1" >"$file"

append() {
  sleep 2
  local last="$1"
  local url="https://repology.org/api/v1/projects/$last/?inrepo=nix_unstable&outdated=1"
  fetch "$url" >>"$file"
}

while true; do
  last=$(jq --sort-keys --raw-output 'keys | last' <"$file")

  append "$last"

  jq --slurp add "$file" | sponge "$file"

  final=$(jq --sort-keys --raw-output 'keys | last' <"$file")
  if [[ $last == "$final" ]]; then
    break
  fi
done

jq -r '
  to_entries |
  map(select(.value | type == "array")) |
  map({
    name: (
      .value |
      map(select(.repo == "nix_unstable")) |
      .[0] |
      .srcname
    ),
    oldVersion: (
      .value |
      map(select(.repo == "nix_unstable" and .status == "outdated")) |
      .[0] |
      .version
    ),
    newVersion: (
      .value |
      map(select(.status == "newest" and .version != null)) |
      .[0] |
      .version
    ),
    url: "https://repology.org/project/\(.key)/versions"
  }) |
  map(select(.newVersion != null)) |
  map("\(.name) \(.oldVersion) \(.newVersion) \(.url)") |
  join("\n")
' <"$file" | sort

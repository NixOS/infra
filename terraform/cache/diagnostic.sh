#!/usr/bin/env nix-shell
#!nix-shell -i bash -p bind.dnsutils -p mtr -p curl -p netcat
# shellcheck shell=bash
# impure: needs ping
#
# Run this script if you are having issues with cache.nixos.org and paste the
# output URL in a new issue in the same repo.
#

domain=${1:-cache.nixos.org}

run() {
  echo "> $*"
  "$@" |& sed -e "s/^/    /"
  printf "Exit: %s\n\n\n" "$?"
}

curl_w="
time_namelookup:    %{time_namelookup}
time_connect:       %{time_connect}
time_appconnect:    %{time_appconnect}
time_pretransfer:   %{time_pretransfer}
time_redirect:      %{time_redirect}
time_starttransfer: %{time_starttransfer}
time_total:         %{time_total}
"

curl_test() {
  curl -w "$curl_w" -v -o /dev/null "$@"
}

termbin() {
  url=$(cat | nc termbin.com 9999)
  echo "Pasted at: $url"
}

(
  echo "domain=$domain"
  run dig -t A "$domain"
  run ping -c1 "$domain"
  run ping -4 -c1 "$domain"
  run ping -6 -c1 "$domain"
  run mtr -c 20 -w -r "$domain"
  run curl_test -4 "http://$domain/"
  run curl_test -6 "http://$domain/"
  run curl_test -4 "https://$domain/"
  run curl_test -6 "https://$domain/"
  run curl -I -4 "https://$domain/"
  run curl -I -4 "https://$domain/"
  run curl -I -4 "https://$domain/"
  run curl -I -6 "https://$domain/"
  run curl -I -6 "https://$domain/"
  run curl -I -6 "https://$domain/"
) | tee /dev/stderr | termbin

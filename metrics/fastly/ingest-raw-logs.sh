#!/usr/bin/env bash

set -e

region=eu-west-1

from_date_incl="$1"
to_date_excl="$2"

[[ -n $from_date_incl ]]
[[ -n $to_date_excl ]]

run_query() {
  local name="$1"
  local query="$2"

  res=$(aws athena start-query-execution \
    --region $region \
    --result-configuration "OutputLocation=s3://nixos-athena/ingestion/$name/" \
    --query-string "$query")

  execution_id="$(printf "%s" "$res" | jq -r -e .QueryExecutionId)"
  [[ -n $execution_id ]]

  echo "Started query $name as $execution_id."

  printf "Waiting..."
  while true; do
    res="$(aws athena get-query-execution --region $region --query-execution-id "$execution_id")"
    status="$(printf %s "$res" | jq -r -e .QueryExecution.Status.State)"
    if [[ $status == RUNNING || $status == QUEUED ]]; then
      printf "."
      sleep 1
      continue
    fi
    if [[ $status == SUCCEEDED ]]; then
      printf " done.\n"
      break
    fi
    printf "\nFailed: %s (%s)\n" "$status" "$res"
    exit 1
  done
}

run_query fill-urls \
  "
    insert into urls
    with requests2 as (select *, date_format(date_parse(timestamp, '%Y-%m-%dT%T+0000'), '%Y-%m-%d') as day from requests)
    select url, count(*) as nr, sum(response_body_size) as total_bytes, sum(elapsed_usec) as total_elapsed, host, day
    from requests2
    where (response_status >= '200' and response_status <= '399') and (day >= '$from_date_incl' and day < '$to_date_excl')
    group by host, day, url;
  "

run_query fill-nix-cache-info \
  "
    insert into nix_cache_info
    with requests2 as (select *, date_format(date_parse(timestamp, '%Y-%m-%dT%T+0000'), '%Y-%m-%d') as day from requests)
    select count(*) as nr, asn, geo_country, geo_region, request_user_agent, day
    from requests2
    where host = 'cache.nixos.org' and url = '/nix-cache-info' and (day >= '$from_date_incl' and day < '$to_date_excl')
    group by day, asn, geo_country, geo_region, request_user_agent;
  "

run_query fill-clients \
  "
    insert into clients
    with requests2 as (select *, date_format(date_parse(timestamp, '%Y-%m-%dT%T+0000'), '%Y-%m-%d') as day from requests)
    select asn, geo_country, geo_region, count(*) as nr, sum(response_body_size) as total_bytes, sum(elapsed_usec) as total_elapsed, host, day
    from requests2
    where (day >= '$from_date_incl' and day < '$to_date_excl')
    group by host, day, asn, geo_country, geo_region;
  "

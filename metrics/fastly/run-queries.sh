#! /bin/sh -e

region=eu-west-1

report_date="$(date +%Y-%m-%d)"

run_query() {
  local name="$1"
  local query="$2"

  res=$(aws athena start-query-execution \
    --region $region \
    --result-configuration OutputLocation=s3://nixos-metrics/$report_date/$name/ \
    --query-string "$query")

  execution_id="$(printf "%s" "$res" | jq -r -e .QueryExecutionId)"
  [[ -n $execution_id ]]

  echo "Started query $name as $execution_id."

  redirect=latest/$name.csv
  aws s3api put-object \
    --bucket nixos-metrics \
    --key $redirect \
    --website-redirect-location /$report_date/$name/$execution_id.csv >/dev/null

  echo "Created redirect http://nixos-metrics.s3-website-eu-west-1.amazonaws.com/$redirect."
}

if true; then

  run_query traffic-per-day \
    "
    select day, host, sum(nr) as nr_requests, sum(total_bytes) as total_bytes
    from urls
    group by day, host
    order by day, host
  "

  run_query traffic-per-country \
    "
    select geo_country, sum(nr) as nr_requests, sum(total_bytes) as total_bytes
    from clients
    group by geo_country
    order by total_bytes desc
  "

  run_query cache-info-requests-per-day \
    "
    select day, sum(nr) as cache_info_requests
    from nix_cache_info
    group by day
    order by day
  "

  run_query cache-info-requests-per-day-not-hosted \
    "
    select day, sum(nr) as cache_info_requests
    from nix_cache_info
    where asn not in (select asn_nr from hosting_asns)
    group by day
    order by day
  "

  run_query cache-info-requests-per-day-per-ua \
    "
    with tmp as
      (select *, regexp_replace(regexp_replace(request_user_agent, '.* Nix', 'Nix'), 'pre[^ ]*', 'pre*') as cleaned_ua from nix_cache_info)
    select day, cleaned_ua, sum(nr) as cache_info_requests
    from tmp
    group by day, cleaned_ua
    order by day, cache_info_requests desc
  "

  run_query flake-registry-requests-per-day \
    "
    select day, sum(nr) as total_requests
    from urls
    where host = 'channels.nixos.org' and url like '%/flake-registry.json'
    group by day
    order by day
  "

  run_query top-store-paths \
    "
    select path, sum(nr) as total_requests
    from urls
    join all_paths on regexp_replace(regexp_replace(url, '.narinfo', ''), '/', '') = regexp_replace(regexp_replace(path, '/nix/store/', ''), '-.*', '')
    where
      host = 'cache.nixos.org'
      and url like '%.narinfo'
    group by path
    having sum(nr) > 100
    order by total_requests desc
  "

  run_query narinfo-queries-per-release \
    "
    with tmp as
      (select distinct path, regexp_replace(regexp_replace(regexp_replace(regexp_replace(release_name, 'pre.*', 'pre'), 'alpha.*', ''), 'beta.*', 'beta'), '\.[0-9]+\.[0-9a-f][0-9a-f][0-9a-f][0-9a-f]+$', '') as release from release_paths)
    select release, sum(nr) as total_requests
    from urls
    join tmp on regexp_replace(regexp_replace(url, '.narinfo', ''), '/', '') = regexp_replace(regexp_replace(path, '/nix/store/', ''), '-.*', '')
    where
      host = 'cache.nixos.org'
      and url like '%.narinfo'
    group by release
    order by total_requests desc
  "

  run_query nix-installer-downloads \
    "
    select day, sum(nr)
    from urls
    where
      host = 'releases.nixos.org'
      and regexp_like(url, '^/nix/nix-[^/]+/install$')
    group by day
    order by day
  "

  run_query nix-installer-architectures \
    "
    select arch, sum(nr) as count from
      (select url, nr, regexp_replace(regexp_replace(url, '/nix/nix-[^/]+/nix-[^-]+-(rc[^-]*-)?', ''), '.tar.xz', '') as arch
       from urls
       where
         host = 'releases.nixos.org'
         and regexp_like(url, '^/nix/nix-[^/]+/nix-[^-]+-.*tar.xz$'))
    group by arch
    order by count desc
  "

fi

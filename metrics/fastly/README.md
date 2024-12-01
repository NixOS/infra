# Fastly log processing

This flake provides a systemd timer (`./cron.sh`) that every week:

- Ingests raw Fastly logs for {cache,channels,tarballs,releases}.nixos.org
  (which are very big) and aggregates them into a smaller AWS Athena database.

  This is performed by `./ingest-raw-logs.sh`.

- Runs a number of SQL queries against the Athena database and stores them in
  S3.

  This is performed by `./run-queries.sh`.

## AWS Athena database

The Athena database is stored in the NixOS Foundation AWS account. To get the
schema, run

```
# aws athena list-table-metadata --region eu-west-1 --catalog-name AwsDataCatalog --database-name default
```

It has the following external tables:

- `requests`: An external table. These are the raw fastly logs stored in
  s3://fastly-logs-20220622145016462800000001/ as compressed JSON records. Note
  that this bucket has a lifecycle rule that moves logs to Glacier after a few
  weeks. Logs in Glacier are not processed by Athena.

- `asn_list`: A list of ASNs. This can be updated by running
  `./update-asn-list.sh`.

- `hosting-asns`: A list of ASNs belonging to hosting/cloud providers.

- `all_paths`: The set of all store paths known in the hydra.nixos.org database.
  This is used to expand the hash part of `.narinfo` requests (e.g.
  `8kbx6s9nn7060zsdms3br0mk7bjrvbij`) to store paths (e.g.
  `/nix/store/8kbx6s9nn7060zsdms3br0mk7bjrvbij-coreutils-full-9.0`).

  FIXME: describe how to update.

- `release_paths`: All the store paths belonging to NixOS evals in
  hydra.nixos.org, as
  `{project, jobset, eval, release_name, build,
  output, path}` tuples.

  FIXME: describe how to update.

The ingestion script populates the following tables stored in
s3://nixos-athena/fastly-logs-processed/:

- `urls`: For each host/day/url, the total number of requests, bytes and elapsed
  microseconds. This only includes info about successful (2xx/3xx) requests.

- `clients`: For each host/day/ASN/country/region, the total number of requests,
  bytes and elapsed microseconds.

- `nix_cache_info`: For each day/ASN/country/region/user-agent, the number of
  requests for `nix-cache-info`.

## Reports

Currently the following reports are created every week:

- http://nixos-metrics.s3-website-eu-west-1.amazonaws.com/latest/traffic-per-day.csv

  For each day and site, the number of requests and the number of bytes
  transferred.

- http://nixos-metrics.s3-website-eu-west-1.amazonaws.com/latest/traffic-per-country.csv

  For each country, the number of requests and the number of bytes transferred.

- http://nixos-metrics.s3-website-eu-west-1.amazonaws.com/latest/cache-info-requests-per-day.csv

  For each day, the number of requests for
  https://cache.nixos.org/nix-cache-info.

- http://nixos-metrics.s3-website-eu-west-1.amazonaws.com/latest/cache-info-requests-per-day-not-hosted.csv

  The same, but with requests from "hosting" ASNs (e.g. AWS and Hetzner)
  filtered out. Note that Nix caches `nix-cache-info` file for a week, so the
  intent of this report is to gauge the number of active weekly users.

- http://nixos-metrics.s3-website-eu-west-1.amazonaws.com/latest/cache-info-requests-per-day-per-ua.csv

  For each day and user agent (e.g. `Nix/2.12.0`), the number of requests for
  https://cache.nixos.org/nix-cache-info. This is intended to track the adoption
  of Nix releases.

- http://nixos-metrics.s3-website-eu-west-1.amazonaws.com/latest/flake-registry-requests-per-day.csv

  For each day, the number of requests for
  https://channels.nixos.org/flake-registry.json. This is intended to track how
  widely flakes are used.

- http://nixos-metrics.s3-website-eu-west-1.amazonaws.com/latest/top-store-paths.csv

  For each store path listed in `all_paths`, the number of requests for its
  `.narinfo` file.

- http://nixos-metrics.s3-website-eu-west-1.amazonaws.com/latest/narinfo-queries-per-release.csv

  For each major NixOS release (e.g. `nixos-22.05`), the number of requests for
  `.narinfo` files of store paths that are part of an eval of that release.

- http://nixos-metrics.s3-website-eu-west-1.amazonaws.com/latest/nix-installer-downloads.csv

  For each day, the number of downloads of the Nix installer (i.e.
  `https://releases.nixos.org/nix/nix-[^/]+/install`).

- http://nixos-metrics.s3-website-eu-west-1.amazonaws.com/latest/nix-installer-architectures.csv

  For each architecture (e.g. `x86_64-linux`), the number of downloads of the
  Nix binary tarball.

#! /bin/sh -e

export AWS_PROFILE=nixos-org

now=$(date +%s)
#now=$((now - 86400))
prev_week=$((($now / 86400 / 7)))

from_date_incl=$(date +%F --date="@$(($prev_week * 86400 * 7 - 2 * 86400))")
to_date_incl=$(date +%F --date="@$(($prev_week * 86400 * 7 + 5 * 86400))")

echo "Ingesting [$from_date_incl, $to_date_incl)."

#exit 0

./ingest-raw-logs.sh "$from_date_incl" "$to_date_incl"

./run-queries.sh

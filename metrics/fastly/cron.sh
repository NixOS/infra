#! /bin/sh -e

export AWS_PROFILE=fastly-log-processor

now=$(date +%s)
#now=$((now - 86400))
prev_week=$((($now / 86400 / 7)))

from_date_incl=$(date +%F --date="@$(($prev_week * 86400 * 7 - 2 * 86400))")
to_date_excl=$(date +%F --date="@$(($prev_week * 86400 * 7 + 5 * 86400))")

echo "Ingesting [$from_date_incl, $to_date_excl)."

marker="$HOME/weeks-done/$prev_week"

if [[ -e $marker ]]; then
    echo "Already done!"
    exit 0
fi

mkdir -p "$(dirname "$marker")"
touch $marker

./ingest-raw-logs.sh "$from_date_incl" "$to_date_excl"

./run-queries.sh

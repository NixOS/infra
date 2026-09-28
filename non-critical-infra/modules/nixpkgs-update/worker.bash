mkdir -p "$LOGS_DIRECTORY/~workers/"
# This is for public logs at nixpkgs-update-logs.nixos.org/~workers
exec > >(rotatelogs -eD "$LOGS_DIRECTORY/~workers/%Y-%m-%d-${WORKER_NAME}.stdout.log" 86400)
exec 2> >(rotatelogs -eD "$LOGS_DIRECTORY/~workers/%Y-%m-%d-${WORKER_NAME}.stderr.log" 86400 >&2)

socket=/run/nixpkgs-update-supervisor/work.sock

function run-nixpkgs-update {
  exit_code=0
  set -x
  timeout 6h "${NIXPKGS_UPDATE_BIN}" update-batch --pr --outpaths --nixpkgs-review "$attr_path $payload" || exit_code=$?
  set +x
  if [ $exit_code -eq 124 ]; then
    echo "Update was interrupted because it was taking too long."
  fi
  msg="DONE $attr_path $exit_code"
}

msg=READY
while true; do
  response=$(echo "$msg" | socat -t5 UNIX-CONNECT:"$socket" - || true)
  case "$response" in
  "") # connection error; retry
    sleep 5
    ;;
  NOJOBS)
    msg=READY
    sleep 60
    ;;
  JOB\ *)
    read -r attr_path payload <<<"${response#JOB }"
    # If one worker is initializing the nixpkgs clone, the other will
    # try to use the incomplete clone, consuming a bunch of jobs and
    # throwing them away. So we use a crude locking mechanism to
    # run only one worker when there isn't a nixpkgs directory yet.
    # Once the directory exists and this initial lock is released,
    # multiple workers can run concurrently.
    lockdir="$XDG_CACHE_HOME/.nixpkgs.lock"
    if [ ! -e "$XDG_CACHE_HOME/nixpkgs" ] && mkdir "$lockdir"; then
      trap 'rmdir "$lockdir"' EXIT
      run-nixpkgs-update
      rmdir "$lockdir"
      trap - EXIT
      continue
    fi
    while [ -e "$lockdir" ]; do
      sleep 10
    done
    run-nixpkgs-update
    ;;
  esac
done

Imports builders' and their SSH keys from the Packet API. Requires the builder
run this script at startup:

```bash
#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq

set -eux

root_url=$(curl https://metadata.packet.net/metadata | jq -r .phone_home_url | rev | cut -d '/' -f2- | rev)
url="$root_url/events"


tell() {
    data=$(
    echo "{}" \
        | jq '.state = $state | .code = ($code | tonumber) | .message = $message' \
         --arg state "$1" \
         --arg code "$2" \
         --arg message "$3"
    )

    curl -v -X POST -d "$data" "$url"
}

tell succeeded 1001 "$(cat /etc/ssh/ssh_host_ed25519_key.pub)"
```

#!/usr/bin/env python3

import json
import packet
import base64
from pprint import pprint
import subprocess
import sys

def debug(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


def get_devices(manager):
    devices = []

    page = 'projects/{}/devices?page={}'.format(config['project_id'], 1)
    while page is not None:
        debug(page)
        data = manager.call_api(page)
        if data['meta']['next'] is None:
            page = None
        else:
            page = data['meta']['next']['href']

        for device in data['devices']:
            if device['state'] != 'active':
                continue
            if 'spot_instance' not in device:
                continue
            if device['spot_instance'] != True:
                continue

            if not set(device['tags']).isdisjoint(config['skip_tags']):
                continue

            devices.append({
                "hostname": device['hostname'],
                "address": "{}.packethost.net".format(device['short_id']),
                "type": device['plan']['name']
            })

    return devices

def main(config):
    rows = []
    manager = packet.Manager(auth_token=config['token'])
    found = 0
    for device in get_devices(manager):
        found += 1
        debug("# {} ({})".format(device['hostname'], device['address']))
        if device['type'] not in config['plans']:
            debug("# Skipping {} (type {}) as it has no configured plan".format(
                device['hostname'],
                device['type'])
            )
            continue

        default_stats = config['plans'][device['type']]
        if device['hostname'] in config['name_overrides']:
            specific_stats = config['name_overrides'][device['hostname']]
        else:
            specific_stats = {}

        lookup = lambda key: specific_stats.get(key, device.get(key, default_stats.get(key)))
        lookup_default = lambda key, default: default if not lookup(key) else lookup(key)

        r = subprocess.check_output([
                                     "ssh-keyscan",
                                     "-4", # force IPv4
                                     "-T", "5", # Timeout 5 seconds
                                     "-t", "ed25519", # Only ed25519 keys
                                     lookup("address")
                                     ]).decode("utf-8")

        elems = r.split(" ", 1)
        if len(elems) != 2:
            debug("# Skipped due keyscan failed to split on ' '")
            continue
        key = elems[1]

        # root@address system,list /var/lib/ssh.key maxJobs speedFactor feature,list mandatory,features public-host-key
        rows.append(" ".join([
               "{user}@{host}".format(user=lookup("user"),host=lookup("address")),
               ",".join(lookup("system_types")),
               str(lookup("ssh_key")),
               str(lookup("max_jobs")),
               str(lookup("speed_factor")),
               ",".join(lookup_default("features", ["-"])),
               ",".join(lookup_default("mandatory_features", ["-"])),
               base64.b64encode(key.encode()).decode("utf-8")
        ]))

    debug("# {} / {}".format(len(rows),found))
    print("\n".join(rows))

if __name__ == "__main__":
    with open(sys.argv[1]) as config_file:
        config = json.load(config_file)
        main(config)

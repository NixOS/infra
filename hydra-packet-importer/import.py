#!/usr/bin/env python3

import json
import packet
import base64
from pprint import pprint
import subprocess
import sys
from typing import Union, Dict, Any, List, Optional

Device = Dict[str, Any]
DeviceKeys =Union[None, List[Dict[str, Any]], str]

def debug(*args: Any, **kwargs: Any) -> None:
    print(*args, file=sys.stderr, **kwargs)


def get_devices(manager: Any) -> List[Device]:
    devices: List[Device] = []

    page: Optional[str] = 'projects/{}/devices?page={}'.format(config['project_id'], 1)
    while page is not None:
        debug(page)
        data: Dict[str, Any] = manager.call_api(page)
        if data['meta']['next'] is None:
            page = None
        else:
            page = data['meta']['next']['href']

        for device in data['devices']:
            if device['state'] != 'active':
                continue

            if not set(config['mandatory_tags']).issubset(device['tags']):
                continue

            if not set(device['tags']).isdisjoint(config['skip_tags']):
                continue

            host_key = get_device_key(manager, device)
            if host_key is None:
                continue

            devices.append({
                "hostname": device['hostname'],
                "address": "{}.packethost.net".format(device['short_id']),
                "type": device['plan']['name'],
                "host_key": host_key,
            })

    return devices

def get_device_key(manager, device: Device) -> DeviceKeys:
    # ... 50 is probably enough.
    events_url = 'devices/{}/events?per_page=50'.format(device['id'])
    debug(events_url)
    data = manager.call_api(events_url)

    ssh_key = None
    for event in data['events']:
        if event['type'] == 'provisioning.104.01':
            # we reached a "Device connected to DHCP system" event,
            # indicating a reboot.
            #
            # The most first SSH key after DHCP is the one we want,
            # in case someone sends a bogus SSH key to the metadata
            # API after the post-boot hook.
            #
            # If we receive a LOT of spam (> 50 spams!) like that, we
            # will return None because we never reach this message.
            return ssh_key
        if event['type'] == 'user.1001':
            try:
                ssh_key = json.loads(event['body'])
            except:
                ssh_key_parts = event['body'].rsplit(" ", 1)
                if len(ssh_key_parts) == 2:
                    ssh_key = ssh_key_parts[0] + "\n"
                else:
                    debug("# Skipped due keyscan failed to split on ' '")

    return None

def main(config: Dict[str, Any]) -> None:
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

        keys: DeviceKeys = device["host_key"]
        key: Optional[str] = None
        if keys is None:
            debug("# no key data")
        elif isinstance(keys, str):
            key = keys
        else:
            keys_matching = [keyrec["key"] for keyrec in keys
                             if keyrec['system'] in lookup("system_types")]
            keys_matching = sorted(keys_matching)
            if len(keys_matching) > 0:
                key = keys_matching[0]

        if key is None:
            debug("# no matching data")

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


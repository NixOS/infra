#!/usr/bin/env python3

import json
import packet  # type: ignore
import base64
from pprint import pprint
import subprocess
import sys
from typing import Union, Dict, Any, List, Optional
from typing import TypedDict

DeviceKeys = List[Dict[str, Any]]


class Metadata(TypedDict):
    features: List[str]
    max_jobs: int
    system_types: List[str]


class RemoteBuilder(TypedDict):
    metadata: Metadata
    ssh_key: str


class Builder(TypedDict):
    hostname: str
    address: str
    type: str
    remote_builder_info: Union[RemoteBuilder, str]


class HostKey(TypedDict):
    system: str
    port: int
    key: str


def debug(*args: Any, **kwargs: Any) -> None:
    print(*args, file=sys.stderr, **kwargs)


def get_builders(manager: Any) -> List[Builder]:
    builders: List[Builder] = []

    page: Optional[str] = "projects/{}/devices?page={}".format(config["project_id"], 1)
    while page is not None:
        debug(page)
        data: Dict[str, Any] = manager.call_api(page)
        if data["meta"]["next"] is None:
            page = None
        else:
            page = data["meta"]["next"]["href"]

        for device in data["devices"]:
            if device["state"] != "active":
                continue

            if not set(config["mandatory_tags"]).issubset(device["tags"]):
                continue

            if not set(device["tags"]).isdisjoint(config["skip_tags"]):
                continue

            remote_builder_info = get_remote_builder_info(manager, device["id"])
            if remote_builder_info is None:
                continue

            builders.append(
                {
                    "hostname": device["hostname"],
                    "address": "{}.packethost.net".format(device["short_id"]),
                    "type": device["plan"]["name"],
                    "remote_builder_info": remote_builder_info,
                }
            )

    return builders


def get_remote_builder_info(manager, device_id: str) -> Union[RemoteBuilder, str, None]:
    # ... 50 is probably enough.
    try:
        events_url = "devices/{}/events?per_page=50".format(device_id)
        debug(events_url)
        data = manager.call_api(events_url)
    except:
        # 404 probably
        return None

    host_key: Optional[HostKey] = None
    ssh_key: Optional[str] = None
    metadata: Optional[Metadata] = None
    for event in data["events"]:
        if event["type"] == "provisioning.104.01":
            # we reached a "Device connected to DHCP system" event,
            # indicating a reboot.
            #
            # The most first SSH key after DHCP is the one we want,
            # in case someone sends a bogus SSH key to the metadata
            # API after the post-boot hook.
            #
            # If we receive a LOT of spam (> 50 spams!) like that, we
            # will return None because we never reach this message.
            if host_key is not None:
                key = strip_ssh_key_comment(host_key["key"])
                if key is not None:
                    if metadata is not None:
                        return {"metadata": metadata, "ssh_key": key}
                    else:
                        return key
            else:
                return ssh_key
        if event["type"] == "user.1001":
            try:
                host_keys: List[HostKey] = [
                    key for key in json.loads(event["body"]) if key["port"] == 22
                ]
                host_key = host_keys[0]
            except:
                ssh_key = strip_ssh_key_comment(event["body"])
        if event["type"] == "user.1002":
            metadata = json.loads(event["body"])

    return None


def strip_ssh_key_comment(key: str) -> Optional[str]:
    ssh_key_parts = key.rsplit(" ", 1)
    if len(ssh_key_parts) == 2:
        return ssh_key_parts[0]
    else:
        debug("# Skipped due keyscan failed to split on ' '")
        return None


def main(config: Dict[str, Any]) -> None:
    rows = []
    manager = packet.Manager(auth_token=config["token"])
    found = 0
    for builder in get_builders(manager):
        found += 1
        debug("# {} ({})".format(builder["hostname"], builder["address"]))
        if builder["type"] not in config["plans"]:
            debug(
                "# Skipping {} (type {}) as it has no configured plan".format(
                    builder["hostname"], builder["type"]
                )
            )
            continue

        builder_info = builder["remote_builder_info"]
        default_stats = config["plans"][builder["type"]]
        if builder["hostname"] in config["name_overrides"]:
            specific_stats = config["name_overrides"][builder["hostname"]]
        else:
            specific_stats = {}
        lookup = lambda key: specific_stats.get(
            key, builder.get(key, default_stats.get(key))
        )

        lookup_default = (
            lambda key, default: default if not lookup(key) else lookup(key)
        )

        if isinstance(builder_info, str):
            key = builder_info
            # root@address system,list /var/lib/ssh.key maxJobs speedFactor feature,list mandatory,features public-host-key
            rows.append(
                " ".join(
                    [
                        "{user}@{host}".format(
                            user=lookup("user"), host=lookup("address")
                        ),
                        ",".join(lookup("system_types")),
                        str(lookup("ssh_key")),
                        str(lookup("max_jobs")),
                        str(lookup("speed_factor")),
                        ",".join(lookup_default("features", ["-"])),
                        ",".join(lookup_default("mandatory_features", ["-"])),
                        base64.b64encode(key.encode()).decode("utf-8"),
                    ]
                )
            )
        else:
            # root@address system,list /var/lib/ssh.key maxJobs speedFactor feature,list mandatory,features public-host-key
            rows.append(
                " ".join(
                    [
                        "{user}@{host}".format(
                            user=lookup("user"), host=lookup("address")
                        ),
                        ",".join(builder_info["metadata"]["system_types"]),
                        str(lookup("ssh_key")),
                        str(builder_info["metadata"]["max_jobs"]),
                        str(lookup("speed_factor")),
                        ",".join(builder_info["metadata"]["features"]),
                        ",".join(lookup_default("mandatory_features", ["-"])),
                        base64.b64encode(builder_info["ssh_key"].encode()).decode(
                            "utf-8"
                        ),
                    ]
                )
            )

    debug("# {} / {}".format(len(rows), found))
    print("\n".join(rows))


if __name__ == "__main__":
    with open(sys.argv[1]) as config_file:
        config = json.load(config_file)
        main(config)

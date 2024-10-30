#!/usr/bin/env python3

import json
import packet  # type: ignore
import base64
import sys
from typing import Dict, Any, List, Optional
from typing import TypedDict

DeviceKeys = List[Dict[str, Any]]


class Metadata(TypedDict):
    user: Optional[str]
    features: List[str]
    mandatory_features: List[str]
    max_jobs: int
    system_types: List[str]
    speed_factor: Optional[int]


class RemoteBuilder(TypedDict):
    metadata: Metadata
    ssh_key: str


class Builder(TypedDict):
    hostname: str
    address: str
    remote_builder_info: RemoteBuilder


class HostKey(TypedDict):
    system: str
    port: int
    key: str


class Plan(TypedDict):
    name: str


class Device(TypedDict):
    state: str
    tags: str
    id: str
    hostname: str
    short_id: str
    plan: Plan


class ProjectDeviceList(TypedDict):
    meta: Dict[str, Any]
    devices: List[Device]


def debug(*args: Any, **kwargs: Any) -> None:
    print(*args, file=sys.stderr, **kwargs)


def get_builders(manager: Any) -> List[Builder]:
    builders: List[Builder] = []

    page: Optional[str] = "projects/{}/devices?page={}".format(config["project_id"], 1)
    while page is not None:
        debug(page)
        data: ProjectDeviceList = manager.call_api(page)
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
                    "remote_builder_info": remote_builder_info,
                }
            )

    return builders


def get_remote_builder_info(manager, device_id: str) -> Optional[RemoteBuilder]:
    # ... 50 is probably enough.
    try:
        events_url = "devices/{}/events?per_page=50".format(device_id)
        debug(events_url)
        data = manager.call_api(events_url)
    except Exception:
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
                ssh_key = strip_ssh_key_comment(host_key["key"])
                if ssh_key is not None and metadata is not None:
                    return {"metadata": metadata, "ssh_key": ssh_key}
            return None
        if event["type"] == "user.1001":
            try:
                host_keys: List[HostKey] = [
                    key for key in json.loads(event["body"]) if key["port"] == 22
                ]
                host_key = host_keys[0]
            except Exception:
                pass
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

        builder_info = builder["remote_builder_info"]

        # root@address system,list /var/lib/ssh.key maxJobs speedFactor feature,list mandatory,features public-host-key
        rows.append(
            " ".join(
                [
                    "{user}@{host}".format(
                        user=builder_info["metadata"].get("user", "root"),
                        host=builder["address"],
                    ),
                    ",".join(builder_info["metadata"]["system_types"]),
                    str(config["ssh_key"]),
                    str(builder_info["metadata"]["max_jobs"]),
                    str(builder_info["metadata"].get("speed_factor", 1)),
                    ",".join(builder_info["metadata"]["features"]),
                    ",".join(builder_info["metadata"].get("mandatory_features", ["-"])),
                    base64.b64encode(builder_info["ssh_key"].encode()).decode("utf-8"),
                ]
            )
        )

    debug("# {} / {}".format(len(rows), found))
    print("\n".join(rows))


if __name__ == "__main__":
    with open(sys.argv[1]) as config_file:
        config = json.load(config_file)
        main(config)

#!/usr/bin/env python3

import requests
from dateutil.parser import parse
from prometheus_client import Counter, Histogram, Gauge, start_http_server, REGISTRY
import time
import sys
from pprint import pprint
import json


def new_revision_registry():
    return Gauge(
        "channel_revision",
        "Current revision, exported as a hack",
        ["channel", "revision"],
        registry=None
    )


CHANNEL_REQUEST_TIME = Histogram(
    "channel_request_time", "Time spent requesting channel data"
)
CHANNEL_UPDATE_TIME = Gauge(
    "channel_update_time",
    "Total number of failures to fetch spot market prices",
    ["channel"],
)
CHANNEL_CURRENT = Gauge(
    "channel_current",
    "If a channel is expected to be current",
    ["channel"],
)
CHANNEL_REQUEST_FAILURES = Counter(
    "channel_request_failures_total",
    "Number of channel status requests which have failed",
)

@CHANNEL_REQUEST_TIME.time()
def measure_channel(name):
    try:
        with CHANNEL_REQUEST_FAILURES.count_exceptions():
            result = requests.get(f"https://nixos.org/channels/{name}/git-revision")
        return {
            "timestamp": parse(result.headers["last-modified"]).timestamp(),
            "revision": result.text
        }
    except Exception as e:
        pprint(e)


if __name__ == "__main__":
    start_http_server(9402)

    with open(sys.argv[1]) as channel_data:
        channels = json.load(channel_data)

    previous_channel_revision = None
    while True:
        CHANNEL_REVISION = new_revision_registry()
        for (channel, about) in channels.items():
            measurement = measure_channel(channel)
            if measurement is not None:
                CHANNEL_UPDATE_TIME.labels(channel=channel).set(measurement['timestamp'])
                CHANNEL_REVISION.labels(channel=channel, revision=measurement['revision']).set(1)
                CHANNEL_CURRENT.labels(channel=channel).set(int(about['current']))

        if previous_channel_revision is not None:
            REGISTRY.unregister(previous_channel_revision)
        REGISTRY.register(CHANNEL_REVISION)
        previous_channel_revision = CHANNEL_REVISION
        time.sleep(55)

#!/usr/bin/env python3

import requests
from dateutil.parser import parse
from prometheus_client import Counter, Histogram, Gauge, start_http_server, REGISTRY
import time
import sys
from pprint import pprint
import json


CHANNEL_REVISION = Gauge(
    "channel_revision",
    "Current revision, exported as a hack",
    ["channel", "revision"],
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
            result = requests.get(f"https://nixos.org/channels/{name}/git-revision", timeout=10)

            try:
                return {
                    "timestamp": parse(result.headers["last-modified"]).timestamp(),
                    "revision": result.text
                }
            except KeyError as e:
                print(f"Got KeyError after getting our result for {name}:")
                pprint(e)
                pprint(result)

    except Exception as e:
        print(f"Got a mystery error for {name}:")
        pprint(e)


if __name__ == "__main__":
    start_http_server(9402)

    with open(sys.argv[1]) as channel_data:
        channels = json.load(channel_data)

    revisions = {}

    while True:
        for (channel, about) in channels.items():
            measurement = measure_channel(channel)
            if measurement is not None:
                revision = measurement['revision']
                CHANNEL_UPDATE_TIME.labels(channel=channel).set(measurement['timestamp'])
                CHANNEL_REVISION.labels(channel=channel, revision=measurement['revision']).set(1)
                CHANNEL_CURRENT.labels(channel=channel).set(int(about['current']))
                print('updated {}'.format(channel))
                previous_revision = revisions.pop(channel, None)
                revisions[channel] = revision
                if previous_revision and previous_revision != revision:
                    CHANNEL_REVISION.remove(channel, previous_revision)

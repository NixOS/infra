#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3 -p python3Packages.prometheus_client


import subprocess
import json
from prometheus_client.core import GaugeMetricFamily, CounterMetricFamily
from prometheus_client import CollectorRegistry, generate_latest, start_http_server
from pprint import pprint
import time

class NixosSystemCollector:
    def collect(self):
        # note: Gauges because of rollbacks.
        current_system = GaugeMetricFamily(
            "nixos_current_system_time_seconds",
            "The time the system's current generation was registered in the Nix database.",
            labels=["version_id"]
        )
        current_system.add_metric([self.get_version_id("/run/current-system")],
                                  self.get_time("/run/current-system"))
        yield current_system

        booted_system = GaugeMetricFamily(
            "nixos_booted_system_time_seconds",
            "The time the system's booted generation was registered in the Nix database.",
            labels=["version_id"]
        )
        booted_system.add_metric([self.get_version_id("/run/booted-system")], self.get_time("/run/booted-system"))
        yield booted_system

    def get_version_id(self, path):
        result = subprocess.run(
            [ "bash", "-c", f"source {path}/etc/os-release; echo $VERSION_ID" ],
            stdout=subprocess.PIPE
        )
        if result.returncode == 0:
            return result.stdout.decode("utf-8").strip()

        return None

    def get_time(self, path):
        # nix path-info --json /run/booted-system | jq .[0].registrationTime
        result = subprocess.run(
            [ "nix", "path-info", "--json", path ],
            stdout=subprocess.PIPE
        )
        if result.returncode == 0:
            parsed = json.loads(result.stdout)
            return parsed[0]['registrationTime']

        return 0

registry = CollectorRegistry()
registry.register(NixosSystemCollector())

if __name__ == '__main__':
    # Start up the server to expose the metrics.
    start_http_server(9300, registry=registry)

    while True:
        time.sleep(100000)


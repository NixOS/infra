#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p "python3.withPackages (ps: with ps; [ prometheus-client packaging ])"


import json
import os
import subprocess
import sys
import time
from collections.abc import Iterator

from packaging.version import Version
from prometheus_client import CollectorRegistry, start_http_server
from prometheus_client.core import GaugeMetricFamily


class NixosSystemCollector:
    def __init__(self) -> None:
        nix_version = self.get_nix_version()

        # https://github.com/NixOS/nix/pull/9242
        self.nix_path_info_returns_object = nix_version >= Version("2.19.0")

    def get_nix_version(self) -> Version:
        result = subprocess.run(
            ["nix", "--version"], stdout=subprocess.PIPE, check=False
        )

        if result.returncode == 0:
            response = result.stdout.decode().strip()
            return Version(response.split()[-1])
        print("Failed to determine nix version", file=sys.stderr)
        sys.exit(1)

    def collect(self) -> Iterator[GaugeMetricFamily]:
        # note: Gauges because of rollbacks.
        current_system = GaugeMetricFamily(
            "nixos_current_system_time_seconds",
            "The time the system's current generation was registered in the Nix database.",
            labels=["version_id"],
        )
        current_system.add_metric(
            [self.get_version_id("/run/current-system")],
            self.get_time("/run/current-system"),
        )
        yield current_system

        booted_system = GaugeMetricFamily(
            "nixos_booted_system_time_seconds",
            "The time the system's booted generation was registered in the Nix database.",
            labels=["version_id"],
        )
        booted_system.add_metric(
            [self.get_version_id("/run/booted-system")],
            self.get_time("/run/booted-system"),
        )
        yield booted_system

        current_system_kernel_booted = GaugeMetricFamily(
            "nixos_current_system_kernel_booted",
            "Whether the currently booted kernel matches the one in the current generation.",
            labels=[],
        )
        booted_kernel = self.get_kernel_out("/run/booted-system")
        current_kernel = self.get_kernel_out("/run/current-system")

        current_system_kernel_booted.add_metric([], booted_kernel == current_kernel)
        yield current_system_kernel_booted

    def get_version_id(self, path: str) -> str:
        result = subprocess.run(
            ["bash", "-c", f"source {path}/etc/os-release; echo $VERSION_ID"],
            stdout=subprocess.PIPE,
            check=False,
        )
        if result.returncode == 0:
            return result.stdout.decode("utf-8").strip()

        return None

    def get_kernel_out(self, path: str) -> str:
        return os.path.dirname(os.readlink(os.path.join(path, "kernel")))

    def get_time(self, path: str) -> int:
        result = subprocess.run(
            ["nix", "path-info", "--json", path], stdout=subprocess.PIPE, check=False
        )
        if result.returncode == 0:
            parsed = json.loads(result.stdout)

            if self.nix_path_info_returns_object:
                # nix path-info --json /run/booted-system | jq .[].registrationTime
                for path_info in parsed.values():
                    return path_info["registrationTime"]
            else:
                # nix path-info --json /run/booted-system | jq .[0].registrationTime
                return parsed[0]["registrationTime"]

        return 0


def main() -> None:
    registry = CollectorRegistry()
    registry.register(NixosSystemCollector())

    # Start up the server to expose the metrics.
    start_http_server(9300, registry=registry)

    while True:
        time.sleep(100000)


if __name__ == "__main__":
    main()

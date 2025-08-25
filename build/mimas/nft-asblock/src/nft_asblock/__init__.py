import sys
import time
from ipaddress import ip_network
from pathlib import Path
from subprocess import CalledProcessError, run
from typing import Final

import httpx
import typer

RTTABLE_CACHE: Final = Path("/var/lib/nft-asblock/table.txt")
NFT_TABLE: Final = "abuse"
NFT_IPV4_SET: Final = "blocked4"
NFT_IPV6_SET: Final = "blocked6"


def get_rttable() -> str:
    def fetch() -> str:
        url = "https://bgp.tools/table.txt"
        headers = {"User-Agent": "nixos.org infra - infra@nixos.org"}
        response = httpx.get(url, headers=headers)
        assert response.status_code == 200
        return response.text

    try:
        mtime = RTTABLE_CACHE.stat().st_mtime
    except FileNotFoundError:
        mtime = None

    # don't pull more often than every two hours
    if not mtime or time.time() - mtime > 2 * 3600:
        print("Pulling routing table from bgp.tools", file=sys.stderr)
        data = fetch()
        with RTTABLE_CACHE.open("w") as fd:
            fd.write(data)
    else:
        print("Loading routing table from cache", file=sys.stderr)
        with RTTABLE_CACHE.open() as fd:
            data = fd.read()

    return data


def nft_block(prefixes: set[str]) -> None:
    networks = map(ip_network, prefixes)

    for network in networks:
        print(f"\nBlocking {network}...", file=sys.stderr, end="")
        try:
            run(
                [
                    "nft",
                    "add",
                    "element",
                    "inet",
                    NFT_TABLE,
                    NFT_IPV4_SET if network.version == 4 else NFT_IPV6_SET,
                    "{",
                    str(network),
                    "}",
                ],
                check=True,
            )
        except CalledProcessError:
            continue


def main(autnums: list[str]) -> None:
    rttable = get_rttable()

    prefixes = set()
    for line in rttable.splitlines():
        try:
            prefix, autnum = line.split()
        except ValueError:
            continue
        if autnum in autnums:
            prefixes.add(prefix)
    nft_block(prefixes)

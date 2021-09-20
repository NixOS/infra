# NixOS project resource inventory

This is the current list of hardware and services that everyone has access to.

# Accounts
## GitHub

owner: Eelco, Rob, Domen, Garbas

## Domains

owner: Eelco
* nixos.org - https://www.uniteddomains.com/

## DNS

owner: Eelco
Managed manually be Eelco via the United Domains web UI

## AWS account

owner:  Infor
alias: lb-nixos
access: Rob and Eelco

## Packet.net

owner: Graham

## Hetzner Cloud

owner: Graham
(for ofborg)

## IRC logging bot

owner: @samueldr
url: https://logs.nix.samueldr.com/nixos/
nick: <code>{\`-\`}</code>
config: https://gitlab.com/samueldr.nix/overlays/irclogger

## Channels.nix.gsc.io

owner: Graham

Tracks all the channel updates

Gives you a graph when all the channels where updated and history.

To help bisect things.

hosted on Packet (personal account)

## search.nix.gsc.io

owner: Graham

Searches all of the nixos project repositories with editor integration.

Useful for spelunking.

hosted on Packet (personal account)

## events.nix.gsc.io

owner: Graham

rabbit MQ instance which can send you all the NixOS organization activity.

hosted on Packet (personal account)

## nix.ci

owner: Graham

ofborg instance and logs

hosted on Packet.

## howoldis.herokuapp.com

owner: madjar/howoldis
url: https://howoldis.herokuapp.com/
repo: http://github.com/madjar/howoldis

Domen might have access

Tells you how old channels are and some doc

## arch64 community builder

owner: Graham
access: community members that have asked access to it
host: Packet

lots of cores to build for the aarch64 platform

## nixcon2017.org

owner: Christine?


## nixcon2018.org

owner: zimbatm


## YouTube channel for recorded talks

owner: Cillian?
url: https://www.youtube.com/channel/UCjqkNrQ8F3OhKSCfCgagWLg


## NixOS community wiki + bot

owner: @fadenb
access: see https://nixos.wiki/wiki/NixOS_Wiki:About

## Twitter accounts

**nixpkg**
owner: Graham

**nixos_org**
owner: Rob Vermaas

**nixcon2017**
owner: Christine?

**nixcon2018**
owner: zimbatm


## IRC

Group registration on FreeNode. Eelco and Graham can get OP on all channels about NixOS.

The group owns:

    #nix
    #nix-*
    #nixos-*

`#nix` is invite only and is empty, it only redirects to `#nixos`

**List of common channels:**

`**#nixos-dev**`

`#``**nixos**`

1 niksnut +AFRefiorstv [modified ? ago]
17:30 2 goodwill +o [modified 3y 36w 6d ago]  - 
17:30 3 kmicu +o [modified 2y 32w 5d ago]   long time member - left 4 months ago
17:30 4 gchristensen +o [modified 1y 37w 1d ago]

`**#nixos-borg**`
`**#nixos-aarch64**`
`**#nix-darwin**`
`#nixos-chat`
`**#nix-core**`
`**#nixos-security**`
`**#nixos-bots**`
`**#nixos-docs**`
`**#nixos-wiki**`
`**#nixos-on-your-router**`




## cachix.org

owner: Domen

# Hardware
## On Packet.net

owner: Graham


2 builders: aarch64 packet type 2 : for hydra

1 aarch64 for ofborg *and* community use

## delft

Univesity Data Center that contains a bunch of machines.


- delft/machines.nix that has all the IPs and mac address of machines there
- hydra (machine name); build slave
- lucifer: build slave

+ bunch of dead machines


## Hetzner:

owner: Eelco and Rob, owned by the NixOS Foundation

“chef”: runs hydra.nixos.org, postgresql database, queue runner, hydra provisioner (might move to the bastion). binary cache signing keys.

monitoring:
**DataDog, accessible by Eelco (and Rob?) (Amine?) on the Infor account**

## Mac Minis

owner: the NixOS Foundation
access: Dan, Eelco, Rob, Graham
role: build machines

Running at the Utrechs Infor office on a shelf somewhere

## Mac Stadium

owner: MacStadium and rented to daniel peebles or the foundation?
role: build machines

Eelco had a root password

## hydra-provisioner

?

## nixos-org

owner: LogicBlox EC2 instance

deployed from Eelco’s laptop

runs the website
runs the channel mirror script, systemd services with timers, updates /releases buckets and the nixpkgs-channels repository (repo: nixos-channel-scripts)

The tarball mirror script is running from that machine.

## bastion server

owner: LogicBlox EC2 instance

running in the lb-nixos AWS account

going to be used to apply NixOps


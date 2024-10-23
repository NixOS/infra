# Deploying to darwin

See [inventory](../docs/inventory.md).

## At Graham's place

We have mac-mini's are in [Grahams](https://github.com/grahamc) house,
that only [@cole-h](https://github.com/cole-h) can deploy.

- These are getting erased and automatically redeployed from the configuration in this directory.

## Hetzner

Additional we have five M1 builders at Hetzner online:

- enormous-catfish.mac.nixos.org
- growing-jennet.mac.nixos.org
- intense-heron.mac.nixos.org
- maximum-snail.mac.nixos.org
- sweeping-filly.mac.nixos.org

These are maintained by the build infra team.

### Update

```
darwin-rebuild switch --flake github::nixos/infra#arm64
```


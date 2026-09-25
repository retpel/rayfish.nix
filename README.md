# rayfish.nix

A Nix package and service module for [Rayfish](https://rayfish.xyz), a P2P mesh
VPN built on iroh. One `module.nix` covers both nix-darwin (launchd) and NixOS
(systemd).

The package uses upstream prebuilt release binaries and does not compile
Rayfish locally. Release `v0.5.0` is pinned with SHA-256 checksums for:

- Apple Silicon macOS (`aarch64-darwin`)
- ARM64 Linux (`aarch64-linux`)
- x86_64 Linux (`x86_64-linux`)

Upstream does not publish an Intel macOS binary, so `x86_64-darwin` is
unsupported. On Linux the binaries are patched with `autoPatchelfHook` so they
run on NixOS.

## Usage

```nix
{
  inputs.rayfish.url = "github:retpel/rayfish.nix";
  inputs.rayfish.inputs.nixpkgs.follows = "nixpkgs";

  # nix-darwin
  darwinConfigurations.<host> = nix-darwin.lib.darwinSystem {
    modules = [
      inputs.rayfish.darwinModules.default
      { services.rayfish.enable = true; }
    ];
  };

  # NixOS
  nixosConfigurations.<host> = nixpkgs.lib.nixosSystem {
    modules = [
      inputs.rayfish.nixosModules.default
      { services.rayfish.enable = true; }
    ];
  };
}
```

`darwinModules.default` and `nixosModules.default` are the same module. It
detects nix-darwin from the `launchd` option.

## Options

| Option | Default | Platform | Description |
|---|---|---|---|
| `services.rayfish.enable` | `false` | both | Run the Rayfish daemon and put `ray` on `PATH`. |
| `services.rayfish.package` | this flake's package | both | Rayfish package to run. No overlay needed. |
| `services.rayfish.resolver.enable` | `true` | macOS | Write `/etc/resolver/ray` so `.ray` names resolve through Rayfish's DNS (`200::53`) instead of another VPN's local resolver. |
| `services.rayfish.rayFix.enable` | `true` | macOS | Install `sudo ray-fix`, which points the Rayfish DNS and active peer routes back at the Rayfish utun after Rayfish or another VPN (e.g. WARP) replaces a utun interface or address. |

## Service

- **macOS:** launchd daemon `com.rayfish.vpn`, logging to
  `/var/log/rayfish.log`. It waits for the Nix store to be mounted at boot and
  restarts after a failed exit.
- **NixOS:** systemd unit `rayfish.service`, started after
  `network-online.target` and restarted on failure.

Both run the binary straight from the Nix store.

## The `ray` guard

The `ray` on `PATH` is a wrapper that refuses commands that would install,
replace, or manage the service outside Nix: `install`, `uninstall`, `start`,
`stop`, `restart`, `auto-update`, `update` (except `--check`/`--list`), and
`sudo ray up`. Everything else passes through to the real binary at
`libexec/rayfish/ray`.

Upgrade by updating the flake input (`nix flake update rayfish`), not with
`ray update`.

If you previously ran `sudo ray up`, remove the service it installed before
switching (on macOS, `sudo rm /Library/LaunchDaemons/com.rayfish.vpn.plist`),
since `ray uninstall` is blocked.

## Outputs

- `packages.<system>.{rayfish,default}`
- `overlays.default` (adds `pkgs.rayfish`)
- `darwinModules.{rayfish,default}`
- `nixosModules.{rayfish,default}`

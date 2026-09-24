# rayfish.nix

A nix-darwin package and launchd module for [Rayfish](https://rayfish.xyz).

This uses upstream prebuilt release binaries and does not compile Rayfish
locally. Release `v0.5.0` is pinned with SHA-256 checksums for:

- Apple Silicon macOS (`aarch64-darwin`)
- ARM64 Linux (`aarch64-linux`)
- x86_64 Linux (`x86_64-linux`)

The current upstream release does not publish an Intel macOS binary, so
`x86_64-darwin` is intentionally unsupported until Rayfish publishes one or a
source-build package is added.

## Use as a flake input

```nix
inputs.rayfish.url = "github:retpel/rayfish.nix";

# In the darwin system modules list:
inputs.rayfish.darwinModules.default

# In configuration:
services.rayfish.enable = true;
```

For NixOS, add the flake input and module:

```nix
inputs.rayfish.url = "github:retpel/rayfish.nix";

modules = [ inputs.rayfish.nixosModules.default ];
services.rayfish.enable = true;
```

The module owns the `com.rayfish.vpn` launchd daemon and runs the immutable
binary from the Nix store. The `ray` wrapper blocks Rayfish commands that would
install, replace, or manipulate the service outside nix-darwin. Upgrade by
updating this flake input, not with `ray update`.

This has not been tested on macOS in this repository. Run `nix flake check`
and `darwin-rebuild build` before activating it.

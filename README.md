# rayfish.nix

A nix-darwin package and launchd module for [Rayfish](https://rayfish.xyz).

This uses the upstream prebuilt macOS Apple Silicon release binary and does not
compile Rayfish locally. The package is pinned to release `v0.5.0` and its
SHA-256 checksum.

## Use as a flake input

```nix
inputs.rayfish.url = "github:retpel/rayfish.nix";

# In the darwin system modules list:
inputs.rayfish.darwinModules.default

# In configuration:
services.rayfish.enable = true;
```

The module owns the `com.rayfish.vpn` launchd daemon and runs the immutable
binary from the Nix store. The `ray` wrapper blocks Rayfish commands that would
install, replace, or manipulate the service outside nix-darwin. Upgrade by
updating this flake input, not with `ray update`.

This has not been tested on macOS in this repository. Run `nix flake check`
and `darwin-rebuild build` before activating it.

# AGENTS.md

Guidance for coding agents working in this repo. `README.md` is the user-facing
doc; keep it in sync when options, outputs, or behavior change.

## What this is

A Nix flake packaging [Rayfish](https://rayfish.xyz) from upstream prebuilt
release binaries (no local compile), plus one service module shared by
nix-darwin and NixOS. Remote: `retpel/rayfish.nix`.

| File | Role |
|---|---|
| `flake.nix` | Outputs: `packages`, `overlays.default`, `darwinModules`, `nixosModules`. |
| `package.nix` | Fetches the release asset for the host system, installs it at `libexec/rayfish/ray`, wraps it with `ray-guard.sh` as `bin/ray`. Linux builds use `autoPatchelfHook`; Darwin skips fixup. |
| `ray-guard.sh` | `ray` wrapper that blocks self-update and service install, and maps `start`/`stop`/`restart` to launchctl/systemctl on the Nix-managed service (`@REAL@` is substituted at build time). |
| `module.nix` | `services.rayfish.*`. Takes `self` first, then the module args. launchd on Darwin, systemd on NixOS; also `/etc/resolver/ray` and `ray-fix` on Darwin. |
| `.github/workflows/update.yml` | Daily job that bumps `version` and hashes, builds, runs `nix flake check`, and pushes to `main`. |

Supported systems: `aarch64-darwin`, `aarch64-linux`, `x86_64-linux`. Adding
one means a new `releases` entry in `package.nix`, the `systems` list in
`flake.nix`, the asset loop in the workflow, and the README.

## Rules

- **Keep `package.nix` formatting that the updater depends on.** The workflow
  edits it with `sed`: `version` must stay on its own line as
  `  version = "X.Y.Z";` (two-space indent), and each `hash = "...";` line must
  come directly after its `asset = "...";` line. Break either and automatic
  updates silently stop working.
- **One module for both platforms.** Detect nix-darwin with `options ? launchd`,
  not `pkgs.stdenv`, which causes infinite recursion. Put platform-only config
  in the `optionalAttrs isDarwin` / `optionalAttrs (!isDarwin)` blocks, and mark
  platform-only options as such in their description and the README table.
- **Services run `libexec/rayfish/ray` directly**, never the guarded `bin/ray`.
  The guard is only for interactive use.
- **Don't loosen the guard** so `ray` can install, update, or replace its own
  service; Nix owns that. `start`/`stop`/`restart` must keep targeting the
  module's service (`com.rayfish.vpn` / `rayfish.service`), not upstream's.
- On Darwin, the launchd job must keep waiting for the Nix store before
  `exec`ing the daemon; LaunchDaemons can start before `/nix` is mounted.
- `ray-fix` uses absolute paths to macOS system tools (`/sbin/route`,
  `/usr/bin/awk`, …) and `${pkgs.jq}`; keep it that way since it runs under
  `sudo` with a minimal `PATH`.
- Version bumps are normally done by the workflow. If bumping by hand, update
  `version` and all three hashes together (`nix store prefetch-file --json <url>`).

## Checking changes

```sh
nix flake check --all-systems      # evaluates all outputs
nix build .#default                # builds for the current host
./result/bin/ray --version
```

On this Mac only `aarch64-darwin` builds locally; Linux builds are exercised by
CI. To test the module on the machine itself, point the system flake in
`/etc/nix-darwin` at this checkout and run `nh darwin build`. Only run
`nh darwin switch` when asked.

## Commits

Short imperative subject lines with no prefix, matching history
(e.g. `Wait for Nix store before starting Darwin daemon`). The workflow commits
as `Update Rayfish to vX.Y.Z`.

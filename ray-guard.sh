#!/bin/sh
set -eu

real='@REAL@'
subcommand=''
for arg in "$@"; do
  case "$arg" in
    -*) continue ;;
    *) subcommand="$arg"; break ;;
  esac
done

case "$subcommand" in
  update)
    case " ${*:-} " in
      *' --check '*|*' --list '*|*' --help '*|*' -h '*) ;;
      *) echo "rayfish: self-update is disabled; update the Nix flake instead" >&2; exit 1 ;;
    esac
    ;;
  auto-update|install|uninstall|start|stop|restart)
    echo "rayfish: service management is owned by nix-darwin" >&2
    exit 1
    ;;
  up)
    if [ "$(id -u)" = 0 ]; then
      echo "rayfish: root service setup is owned by nix-darwin" >&2
      exit 1
    fi
    ;;
esac

exec "$real" "$@"

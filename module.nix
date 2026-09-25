{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.rayfish;
in {
  options.services.rayfish = {
    enable = mkEnableOption "Rayfish mesh VPN";
    package = mkOption {
      type = types.package;
      default = pkgs.rayfish;
      defaultText = literalExpression "pkgs.rayfish";
      description = "Rayfish package to run.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    launchd.daemons.rayfish = {
      serviceConfig = {
        Label = "com.rayfish.vpn";
        # LaunchDaemons can start before the Nix store is mounted during
        # boot. Wait from the system shell instead of letting launchd cache a
        # missing executable and mark the job failed.
        ProgramArguments = [
          "/bin/sh"
          "-c"
          ''
            while [ ! -x "${cfg.package}/libexec/rayfish/ray" ]; do sleep 1; done
            exec "${cfg.package}/libexec/rayfish/ray" daemon
          ''
        ];
        RunAtLoad = true;
        # Restart after a failed daemon exit instead of leaving the service in
        # launchd's penalty box.
        KeepAlive = {
          SuccessfulExit = false;
        };
        ThrottleInterval = 10;
        StandardOutPath = "/var/log/rayfish.log";
        StandardErrorPath = "/var/log/rayfish.log";
      };
    };
  };
}

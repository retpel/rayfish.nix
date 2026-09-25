self:
{ config, lib, pkgs, ... }:

let
  cfg = config.services.rayfish;
in {
  options.services.rayfish = {
    enable = lib.mkEnableOption "Rayfish mesh VPN";
    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = lib.literalExpression "rayfish.packages.\${pkgs.stdenv.hostPlatform.system}.default";
      description = "Rayfish package to run.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.services.rayfish = {
      description = "Rayfish mesh VPN daemon";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/libexec/rayfish/ray daemon";
        Restart = "on-failure";
        RestartSec = 5;
        User = "root";
      };
    };
  };
}

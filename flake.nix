{
  description = "Rayfish mesh VPN package and nix-darwin module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-darwin, ... }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in {
      packages = forAllSystems (pkgs: {
        rayfish = pkgs.callPackage ./package.nix { };
        default = pkgs.callPackage ./package.nix { };
      });

      darwinModules.default = import ./module.nix;
      darwinModules.rayfish = self.darwinModules.default;
      nixosModules.default = import ./nixos-module.nix;
      nixosModules.rayfish = self.nixosModules.default;

      overlays.default = final: prev: {
        rayfish = final.callPackage ./package.nix { };
      };
    };
}

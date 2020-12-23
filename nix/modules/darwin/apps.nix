{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.apps;
  alfred = pkgs.callPackage ../../apps/alfred.nix { };
  appcleaner = pkgs.callPackage ../../apps/appcleaner.nix { };

in {
  options = with lib; {
    my.apps = {
      enable = mkEnableOption ''
        Whether to enable apps module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      environment.systemPackages = with pkgs; [ alfred appcleaner ];
    };
}

{ pkgs, lib, config, ... }:

let

  cfg = config.my.modules.ssh;

in {
  options = with lib; {
    my.modules.ssh = {
      enable = mkEnableOption ''
        Whether to enable ssh module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      home-manager = {
        users.${config.my.username} = {
          home = {
            file = {
              ".ssh/config" = { source = ../../../config/.ssh/config; };
            };
          };
        };
      };
    };
}

{ pkgs, lib, config, ... }:

let

  cfg = config.my.modules.newsboat;

in {
  options = with lib; {
    my.modules.newsboat = {
      enable = mkEnableOption ''
        Whether to enable newsboat module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      my.user = { packages = with pkgs; [ newsboat w3m ]; };

      home-manager = {
        users.${config.my.username} = {
          home = {
            file = {
              ".config/newsboat" = {
                recursive = true;
                source = ../../../config/newsboat;
              };
            };
          };
        };
      };
    };
}

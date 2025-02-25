{ pkgs, lib, config, options, ... }:

let

  cfg = config.my.modules.kitty;

in
{
  options = with lib; {
    my.modules.kitty = {
      enable = mkEnableOption ''
        Whether to enable kitty module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable (mkMerge [
      # imagemagick is required to show images in the terminal
      (if (builtins.hasAttr "homebrew" options) then {
        homebrew.casks = [ "kitty" ];
        my.user = { packages = with pkgs; [ imagemagick ]; };
      } else {
        my.user = { packages = with pkgs; [ kitty imagemagick ]; };
      })

      {
        my.env = {
          TERMINFO_DIRS = "$KITTY_INSTALLATION_DIR/terminfo";
        };

        my.hm.file = {
          ".config/kitty" = {
            recursive = true;
            source = ../../../config/kitty;
          };
        };
      }
    ]);
}

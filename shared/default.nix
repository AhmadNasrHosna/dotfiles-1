{ config, pkgs, lib, inputs, ... }: {
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = "experimental-features = nix-command flakes";
    binaryCaches = [ "https://nix-community.cachix.org" ];
    binaryCachePublicKeys = [
      "nix-community.cachix. org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    gc = {
      automatic = true;
      options = "--delete-older-than 3d";
    };
  };

  imports = [ ../modules ];

  nixpkgs = {
    config = { allowUnfree = true; };
    overlays = [
      # (import inputs.comma { inherit pkgs; })
      (final: prev: {
        neovim-unwrapped = prev.neovim-unwrapped.overrideAttrs (oldAttrs: {
          version = "master";
          src = inputs.neovim-nightly;
          buildInputs = oldAttrs.buildInputs ++ [ pkgs.tree-sitter ];
        });

        pure-prompt = prev.pure-prompt.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ../overlays/pure-zsh.patch ];
        });

        python3 = prev.python3.override {
          packageOverrides = final: prev: {
            python-language-server =
              prev.python-language-server.overridePythonAttrs
              (old: rec { doCheck = false; });
          };
        };

        # https://github.com/NixOS/nixpkgs/issues/106506#issuecomment-742639055
        weechat = prev.weechat.override {
          configure = { availablePlugins, ... }: {
            plugins = with availablePlugins;
              [ (perl.withPackages (p: [ p.PodParser ])) ] ++ [ python ];
            scripts = with prev.weechatScripts;
              [ wee-slack ]
              ++ final.stdenv.lib.optionals (!final.stdenv.isDarwin)
              [ weechat-notify-send ];
          };
        };
      })
    ];
  };

  time.timeZone = config.settings.timezone;

  users.users.${config.settings.username} = {
    description = "Primary user account";
    shell = [ pkgs.zsh ];
  };

  home-manager = {
    users.${config.settings.username} = {
      xdg = { enable = true; };
      home = {
        # Necessary for home-manager to work with flakes, otherwise it will
        # look for a nixpkgs channel.
        stateVersion =
          if pkgs.stdenv.isDarwin then "20.09" else config.system.stateVersion;
      };
      programs = {
        # Let Home Manager install and manage itself.
        home-manager.enable = true;
      };
    };
  };
}

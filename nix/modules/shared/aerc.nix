{ pkgs, lib, config, ... }:

with config.my;

let

  cfg = config.my.modules.aerc;
  homeDir = config.my.user.home;
  inherit (config.home-manager.users."${username}") xdg;
in
{
  options = with lib; {
    my.modules = {
      aerc = {
        # TODO: support multiple accounts
        enable = mkEnableOption ''
          Whether to enable aerc module
        '';
        account = {
          name = mkOption {
            default = "gabri.me";
            type = with types; uniq str;
          };
          type = mkOption {
            default = "Personal";
            type = with types; uniq str;
          };
        };

        keychain = {
          name = mkOption {
            default = "fastmail.com";
            type = with types; uniq str;
          };
          account = mkOption {
            default = replaceStrings [ "@" ] [ "+mutt@" ] email;
            type = with types; uniq str;
          };
        };

        imap_server = mkOption {
          default = "imap.fastmail.com";
          type = with types; uniq str;
        };

        smtp_server = mkOption {
          default = "smtp.fastmail.com";
          type = with types; uniq str;
        };
      };
    };
  };

  config = with lib;
    mkIf cfg.enable (mkMerge [{
      my.user = { packages = with pkgs; [ aerc isync w3m notmuch pass ]; };

      my.env = {
        MAILDIR =
          "$HOME/.mail"; # will be picked up by .notmuch-config for database.path
        NOTMUCH_CONFIG = "$XDG_CONFIG_HOME/notmuch/config";
        # MAILCAP="$XDG_CONFIG_HOME/mailcap"; # elinks, w3m
        # MAILCAPS="$MAILCAP";   # Mutt, pine
      };

      my.hm.file = {
        ".config/aerc/stylesets" = {
          recursive = true;
          source = ../../../config/aerc/stylesets;
        };

        ".config/aerc/binds.conf" = {
          source = ../../../config/aerc/binds.conf;
        };

        ".config/aerc/accounts.conf" = {
          text = ''
            [${cfg.account.name}]
            smtp-starttls     = yes
            from              = ${config.my.name} <${config.my.email}>
            source            = imaps://${cfg.keychain.account}@${cfg.imap_server}
            source-cred-cmd   = ${xdg.configHome}/zsh/bin/get-keychain-pass '${cfg.keychain.account}' '${cfg.keychain.name}'
            outgoing          = smtps+plain://${cfg.keychain.account}@${cfg.smtp_server}
            outgoing-cred-cmd = ${xdg.configHome}/zsh/bin/get-keychain-pass '${cfg.keychain.account}' '${cfg.keychain.name}'
            copy-to           = Sent
            postpone          = Drafts
            archive           = Archive
            folders-sort      = INBOX, Starred, Drafts, Sent, Trash, Archive, Spam
            source            = maildir://~/.mail/${cfg.account.type}
            # signature-file    = ~/.signature.local

            # [notmuch]
            # source            = notmuch://~/.mail/
            # query-map         = ~/.config/aerc/querymap'';
        };

        ".config/aerc/querymap" = { source = ../../../config/aerc/querymap; };

        ".config/aerc/aerc.conf" = {
          text = ''
            ${builtins.readFile ../../../config/aerc/aerc.conf}

            [filters]
            #
            # Filters allow you to pipe an email body through a shell command to render
            # certain emails differently, e.g. highlighting them with ANSI escape codes.
            #
            # The first filter which matches the email's mimetype will be used, so order
            # them from most to least specific.
            #
            # You can also match on non-mimetypes, by prefixing with the header to match
            # against (non-case-sensitive) and a comma, e.g. subject,text will match a
            # subject which contains "text". Use header,~regex to match against a regex.
            subject,~^\[PATCH=awk -f ${pkgs.aerc}/share/aerc/filters/hldiff
            subject,~^\[RFC=awk -f ${pkgs.aerc}/share/aerc/filters/hldiff
            # text/html=${pkgs.aerc}/share/aerc/filters/html
            text/plain=par -w 120 -
            text/html=w3m -T text/html -cols 120 -dump -o display_image=false -o display_link_number=true
            text/*=awk -f ${pkgs.aerc}/share/aerc/filters/plaintext
            image/*=chafa -
            # image/*=catimg -w $(tput cols) -

            [templates]
            # Templates are used to populate email bodies automatically.
            #

            # The directories where the templates are stored. It takes a colon-separated
            # list of directories.
            #
            # default: /usr/local/share/aerc/templates/
            template-dirs=${pkgs.aerc}/share/aerc/templates/'';
        };
      };
    }]

    );
}

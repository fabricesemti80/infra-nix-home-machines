# Module: SSH Client Configuration
# Purpose: One set of per-host identities for every machine. Private keys stay in
#          1Password; Nix holds only public keys, which select the key to use.
# Platform: macOS serves the keys from the 1Password app's SSH agent. Linux hosts
#           have no 1Password app, so they use the agent forwarded from the Mac,
#           reached through the stable link ~/.ssh/auth-sock (see the end of this
#           file) so that long-lived sessions and the herdr core can use it.
{
  lib,
  pkgs,
  userConfig,
  ...
}: let
  inherit (userConfig) sshKeysByHost;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  agentSocket = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  # Linux hosts read the forwarded agent through a stable link, not $SSH_AUTH_SOCK,
  # so processes started by the herdr core (no such variable) still reach it.
  agent =
    if isDarwin
    then [''IdentityAgent "${agentSocket}"'']
    else ["IdentityAgent ~/.ssh/auth-sock"];
  # Forward the Mac's agent only to hosts that are trusted to use it. Name the
  # 1Password socket: a bare "yes" forwards $SSH_AUTH_SOCK, which can be unset.
  forward = lib.optional isDarwin ''ForwardAgent "${agentSocket}"'';
  # Legacy key files exist only on the Mac; keep them as a fallback there.
  legacy = key: lib.optional isDarwin "IdentityFile ~/.ssh/${key}";

  block = names: lines: "Host ${names}\n${lib.concatMapStrings (l: "  ${l}\n") lines}";

  # Deploy recipes connect to the inventory target IP, so every block lists it.
  hosts = [
    (block "qnap 10.0.40.2" ([
        "HostName 10.0.40.2"
        "User admin-fabrice"
        "Port 22"
        "PreferredAuthentications publickey,password,keyboard-interactive"
        "PasswordAuthentication yes"
        "KbdInteractiveAuthentication yes"
        "PubkeyAuthentication yes"
      ]
      ++ agent
      ++ [
        "IdentityFile ~/.ssh/id_qnap.pub"
        "IdentitiesOnly yes"
        "StrictHostKeyChecking yes"
        "ForwardAgent no"
      ]))

    (block "pve-00 pve-00.krapulax.home 10.0.40.10" ([
        "HostName 10.0.40.10"
        "User root"
        "Port 22"
      ]
      ++ agent
      ++ [
        "IdentityFile ~/.ssh/id_pve_00.pub"
        "IdentitiesOnly yes"
      ]))

    (block "trinity trinity.krapulax.home 10.0.40.50" ([
        "HostName 10.0.40.50"
        "User fs"
        "Port 22"
      ]
      ++ agent
      ++ forward
      ++ [
        "IdentityFile ~/.ssh/id_trinity.pub"
        "IdentitiesOnly yes"
      ]))

    (block "apoc 10.211.55.8" ([
        "HostName 10.211.55.8"
        "User fs"
        "Port 22"
      ]
      ++ agent
      ++ forward
      ++ [
        "IdentityFile ~/.ssh/id_apoc.pub"
      ]
      ++ legacy "id_macbook_fs"
      ++ ["IdentitiesOnly yes"]))

    (block "github.com" ([
        "HostName ssh.github.com"
        "User git"
        "Port 443"
      ]
      ++ agent
      ++ [
        "IdentityFile ~/.ssh/id_github_fs.pub"
        "IdentitiesOnly yes"
      ]))

    (block "gitlab.com" ([
        "HostName altssh.gitlab.com"
        "User git"
        "Port 443"
      ]
      ++ agent
      ++ [
        "IdentityFile ~/.ssh/id_gitlab_fs.pub"
        "IdentitiesOnly yes"
      ]))

    (block "proxmox-pbs-0 10.0.40.20" ([
        "HostName 10.0.40.20"
        "User root"
        "Port 22"
      ]
      ++ agent
      ++ [
        "IdentityFile ~/.ssh/id_proxmox_pbs_0.pub"
        "IdentitiesOnly yes"
      ]))
  ];
in {
  home.file =
    {
      ".ssh/id_apoc.pub".text = "${sshKeysByHost.apoc}\n";
      ".ssh/id_qnap.pub".text = "${sshKeysByHost.qnap}\n";
      ".ssh/id_github_fs.pub".text = "${sshKeysByHost.github}\n";
      ".ssh/id_gitlab_fs.pub".text = "${sshKeysByHost.gitlab}\n";
      ".ssh/id_gitsign_fs.pub".text = "${sshKeysByHost.gitsign}\n";
      ".ssh/id_proxmox_pbs_0.pub".text = "${sshKeysByHost.pbs}\n";
      ".ssh/id_pve_00.pub".text = "${sshKeysByHost.pve00}\n";
      ".ssh/id_trinity.pub".text = "${sshKeysByHost.trinity}\n";
      ".ssh/nix-managed.conf".text =
        # Runs ~/.ssh/agent-link each time ssh reads its config, so even commands
        # started by the herdr core (no login, no prompt) find a live agent.
        lib.optionalString (!isDarwin) ''Match exec "$HOME/.ssh/agent-link"''
        + "\n\n"
        + lib.concatStringsSep "\n" hosts;
    }
    # The Mac's ~/.ssh/config is hand-maintained (OrbStack, LazySSH) and includes
    # the fragment. Linux hosts have nothing else there, so Nix owns it.
    // lib.optionalAttrs (!isDarwin) {
      ".ssh/config".text = "Include ~/.ssh/nix-managed.conf\n";
      # Repoints ~/.ssh/auth-sock at a live forwarded agent socket when it dangles:
      # this login's socket first, then the newest live one. Always exits 0 so it
      # can also run from the Match exec in the ssh config.
      ".ssh/agent-link" = {
        executable = true;
        text = ''
          #!/bin/sh
          link="$HOME/.ssh/auth-sock"
          [ -S "$link" ] && exit 0
          for s in "$SSH_AUTH_SOCK" $(ls -t "$HOME"/.ssh/agent/s.* 2>/dev/null); do
            [ -S "$s" ] || continue
            [ "$s" = "$link" ] && continue
            SSH_AUTH_SOCK=$s ${pkgs.openssh}/bin/ssh-add -l >/dev/null 2>&1
            [ $? -le 1 ] || continue
            ln -sfn "$s" "$link"
            exit 0
          done
          exit 0
        '';
      };
      # sshd runs this at every login, including non-interactive ones such as the
      # transport Herdr keeps open, so the link is current without a shell.
      ".ssh/rc" = {
        executable = true;
        text = ''
          #!/bin/sh
          exec "$HOME/.ssh/agent-link"
        '';
      };
    }
    # Only the 1Password app reads the agent allowlist.
    // lib.optionalAttrs isDarwin {
      ".config/1Password/ssh/agent.toml".text = ''
        [[ssh-keys]]
        item = "id_trinity"
        vault = "ssh-keys"

        [[ssh-keys]]
        item = "id_qnap"
        vault = "ssh-keys"

        [[ssh-keys]]
        item = "id_pve_00"
        vault = "ssh-keys"

        [[ssh-keys]]
        item = "id_proxmox_pbs_0"
        vault = "ssh-keys"

        [[ssh-keys]]
        item = "id_apoc"
        vault = "ssh-keys"

        [[ssh-keys]]
        item = "id_github_fs"
        vault = "ssh-keys"

        [[ssh-keys]]
        item = "id_gitlab_fs"
        vault = "ssh-keys"

        [[ssh-keys]]
        item = "macbook-fs"
        vault = "ssh-keys"

        [[ssh-keys]]
        item = "fs-home-rsa"
        vault = "ssh-keys"

        [[ssh-keys]]
        item = "git-signing-fs"
        vault = "ssh-keys"
      '';
    };

  # Herdr runs panes under its long-lived core daemon, so they never see the agent
  # of the SSH login that connected Herdr. ~/.ssh/auth-sock is a link to a live
  # forwarded socket, kept current by ~/.ssh/agent-link (run at login, at every
  # prompt, and before every ssh); every shell uses the link.
  programs.zsh.initContent = lib.mkIf (!isDarwin) ''
    _ssh_agent_link() { [ -S "$HOME/.ssh/auth-sock" ] || "$HOME/.ssh/agent-link"; }
    _ssh_agent_link
    export SSH_AUTH_SOCK="$HOME/.ssh/auth-sock"
    precmd_functions+=(_ssh_agent_link)
  '';
}

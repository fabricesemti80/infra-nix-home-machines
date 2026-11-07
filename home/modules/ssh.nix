# Module: SSH Client Configuration
# Purpose: Per-host identities backed by the 1Password SSH Agent
# Platform: macOS client
{userConfig, ...}: let
  inherit (userConfig) sshKeysByHost;
  agentSocket = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
in {
  home.file = {
    ".ssh/id_apoc.pub".text = "${sshKeysByHost.apoc}\n";
    ".ssh/id_qnap.pub".text = "${sshKeysByHost.qnap}\n";
    ".ssh/id_github_fs.pub".text = "${sshKeysByHost.github}\n";
    ".ssh/id_gitlab_fs.pub".text = "${sshKeysByHost.gitlab}\n";
    ".ssh/id_proxmox_pbs_0.pub".text = "${sshKeysByHost.pbs}\n";
    ".ssh/id_pve_00.pub".text = "${sshKeysByHost.pve00}\n";
    ".ssh/id_trinity.pub".text = "${sshKeysByHost.trinity}\n";
    ".ssh/nix-managed.conf".text = ''
      Host qnap 10.0.40.2
        HostName 10.0.40.2
        User admin-fabrice
        Port 22
        PreferredAuthentications publickey,password,keyboard-interactive
        PasswordAuthentication yes
        KbdInteractiveAuthentication yes
        PubkeyAuthentication yes
        IdentityAgent "${agentSocket}"
        IdentityFile ~/.ssh/id_qnap.pub
        IdentitiesOnly yes
        StrictHostKeyChecking yes
        ForwardAgent no

      Host pve-00 pve-00.krapulax.home 10.0.40.10
        HostName 10.0.40.10
        User root
        Port 22
        IdentityAgent "${agentSocket}"
        IdentityFile ~/.ssh/id_pve_00.pub
        IdentitiesOnly yes

      Host trinity trinity.krapulax.home 10.0.40.50
        HostName 10.0.40.50
        User fs
        Port 22
        IdentityAgent "${agentSocket}"
        IdentityFile ~/.ssh/id_trinity.pub
        IdentitiesOnly yes

      Host apoc
        HostName 10.211.55.8
        User fs
        Port 22
        IdentityAgent "${agentSocket}"
        IdentityFile ~/.ssh/id_apoc.pub
        IdentityFile ~/.ssh/id_macbook_fs
        IdentitiesOnly yes

      Host github.com
        HostName ssh.github.com
        User git
        Port 443
        IdentityAgent "${agentSocket}"
        IdentityFile ~/.ssh/id_github_fs.pub
        IdentitiesOnly yes

      Host gitlab.com
        HostName altssh.gitlab.com
        User git
        Port 443
        IdentityAgent "${agentSocket}"
        IdentityFile ~/.ssh/id_gitlab_fs.pub
        IdentitiesOnly yes

      Host proxmox-pbs-0
        HostName 10.0.40.20
        User root
        Port 22
        IdentityAgent "${agentSocket}"
        IdentityFile ~/.ssh/id_proxmox_pbs_0.pub
        IdentitiesOnly yes
    '';
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
      item = "id_proxmox"
      vault = "ssh-keys"

      [[ssh-keys]]
      item = "fs-home-rsa"
      vault = "ssh-keys"

      [[ssh-keys]]
      item = "git-signing-fs"
      vault = "ssh-keys"

      [[ssh-keys]]
      vault = "Personal"
    '';
  };
}

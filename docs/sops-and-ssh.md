# SOPS and SSH: setup, migration and recovery

This feature is opt-in. Merging the PR does not decrypt secrets, replace SSH
configuration, change Git signing or modify remote authorized keys. Work through
one machine first. No private key needs to be sent to ChatGPT or pasted into an issue.

## 1. Understand the three kinds of key

| Key | Purpose | Distribution |
| --- | --- | --- |
| Recovery age identity | Edit/recover every encrypted secret | Save privately in 1Password; never deploy to hosts |
| Per-machine age identity | Decrypt only files addressed to that machine | Root-only runtime file on that machine |
| SSH authentication/signing identity | Authenticate to a server or sign Git commits | Prefer one per client/device; store encrypted if provisioning through SOPS |
| SSH host identity | Prove which server you connected to | Unique to each server; do not share across machines |

SOPS uses a data key internally; the recovery age identity is what this guide
calls the recovery key, rather than a shared master key installed everywhere.
The age public recipients and SSH public keys are not secrets.

Ciphertext may be committed even in a public repository. Decrypted keys still
exist locally and are accessible to the owning user/root. SOPS does not protect a
compromised running machine. macOS sops-nix uses disk-backed runtime storage, not
a RAM filesystem; use FileVault and account security as well.

## 2. Get the tools and preserve your current access

From this repository:

```sh
nix develop
```

This adds `age`, `sops` and `ssh-keygen`. It installs no secret. The flake pins
`sops-nix` and follows the existing nixpkgs input. Re-enter this shell if a command
below is unavailable. The 1Password desktop/CLI is already declared for your Mac;
complete its usual account setup separately if needed.

Back up existing SSH files outside this repository:

```sh
umask 077
backup="$HOME/.ssh-migration/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup"
cp -Rp "$HOME/.ssh" "$backup/ssh"
printf 'Backup directory: %s\n' "$backup"
```

This backup contains private keys. Keep it private and protect it like the keys.
Do not remove or rotate existing identities yet. Keep an existing SSH session to
each important target open while testing its new access.

## 3. Generate the recovery age identity and store it in 1Password

Use a private working directory outside the repository:

```sh
umask 077
mkdir -p "$HOME/.config/sops/age"
age-keygen -o "$HOME/.config/sops/age/recovery-age-key.txt"
age-keygen -y "$HOME/.config/sops/age/recovery-age-key.txt"
```

The second command prints the public `age1...` recipient. Record that public
recipient for `.sops.yaml`. The file contains the private `AGE-SECRET-KEY-...`
identity; never commit it. `age-keygen` refuses to replace an existing output.

In 1Password:

1. Create a Secure Note named **Nix SOPS recovery** in your chosen vault.
2. Add a concealed/password field named **age-private-key** containing the private
   `AGE-SECRET-KEY-...` line from the file. Use a trusted local editor to access it.
3. Add a normal field named **age-public-key** with the `age1...` recipient.
4. Note which repository uses it, its creation date, and the bootstrap file path.
5. Reopen the item and verify the saved private identity against the local file.
   Ensure your 1Password recovery arrangements work independently of this Mac.

For this first session you can point SOPS at the protected local file:

```sh
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/recovery-age-key.txt"
```

For later editing sessions, an optional CLI retrieval into a temporary private
file is shown below. Change `Private` to your actual vault name. Do not enable
shell tracing (`set -x`) while handling secrets.

```sh
umask 077
recovery_dir="$(mktemp -d)"
trap 'rm -rf "$recovery_dir"; unset SOPS_AGE_KEY_FILE' EXIT
op read 'op://Private/Nix SOPS recovery/age-private-key' > "$recovery_dir/key.txt"
export SOPS_AGE_KEY_FILE="$recovery_dir/key.txt"
```

Run that in a dedicated shell and exit after editing. The trap removes the
transient file; it does not securely erase disk snapshots. After verifying
1Password recovery, decide whether to retain or remove the original local copy.
Never put this recovery identity in `/var/lib/sops-nix` on every machine.

## 4. Generate a dedicated decryption identity on each managed machine

On **neo**, in the tool shell:

```sh
age_bin="$(command -v age-keygen)"
sudo mkdir -p /var/lib/sops-nix
sudo chmod 700 /var/lib/sops-nix
sudo "$age_bin" -o /var/lib/sops-nix/age-key.txt
sudo chmod 600 /var/lib/sops-nix/age-key.txt
sudo "$age_bin" -y /var/lib/sops-nix/age-key.txt
```

Only the final public `age1...` recipient goes in Git. The private file stays
root-owned on neo. These commands refuse to overwrite an existing age key.

Repeat locally on **apoc** with its own new identity. If its normal shell lacks
the tools, enter `nix shell nixpkgs#age` first. Do not copy neo's private identity
to apoc. You may back up each machine identity in a separate 1Password item,
clearly labelled by machine; the recovery identity can also recover its payloads.

## 5. Configure recipients

```sh
cp -n secrets/.sops.yaml.example .sops.yaml
```

Edit `.sops.yaml`, replacing all three placeholders with actual public recipients.
If only neo is being enrolled, remove the apoc anchor and apoc rule, and remove
apoc from the shared rule until its real recipient exists. Do not leave fake keys.

The rules give:

- `secrets/neo.yaml`: recovery and neo access.
- `secrets/apoc.yaml`: recovery and apoc access.
- `secrets/shared.yaml`: recovery and both machines access.

Keep private per-device authentication keys in the per-device file. Reserve
`shared.yaml` for credentials that truly need to be identical. Every recipient of
a file can decrypt every field in that file, even fields not declared in Nix.

Adding a recipient later requires `sops updatekeys secrets/FILE.yaml`; editing
`.sops.yaml` alone does not re-encrypt existing files.

## 6. Inventory and ingest the Mac's current SSH client configuration

The repository does not contain your live `~/.ssh/config`. Run this on your Mac:

```sh
python3 tools/import-ssh-config.py --label neo
```

This is a dry run. It reports IdentityFile references, included files and commands
requiring review. It never reads identity file contents or executes `Match exec`
commands. After reviewing:

```sh
python3 tools/import-ssh-config.py --label neo --write
```

Review `files/ssh/imported/neo/` locally. The importer preserves separate Include
files, block order, ProxyJump/ProxyCommand and Host/Match directives. It rewrites
local Includes to the managed snapshot directory. Includes outside `~/.ssh`,
unmatched globs and dynamic Includes remain external dependencies, recorded in
`manifest.json`; the snapshot is not self-contained until you resolve those.
The importer refuses cycles, private-key content, large files and overwrites.

Review commands for embedded passwords/tokens before committing anything. Detection
is deliberately limited and is not a guarantee that config is free of secrets.
Keep credentials out of ProxyCommand arguments. Check relative IdentityFile paths:
OpenSSH interprets those relative to its working directory, not the config file.
Prefer explicit `~/.ssh/...` or absolute paths.

In `home/fs/neo.nix`, add:

```nix
my.ssh = {
  enable = true;
  importedConfig = ../../files/ssh/imported/neo;
};
```

No SOPS enrollment is required just to manage SSH config. Before the first home
switch, move only the original config out of Home Manager's way (the full backup
from step 2 stays available):

```sh
mv "$HOME/.ssh/config" "$backup/config-before-home-manager"
```

Then use your normal home switch. If it fails, restore that file before retrying.
Home Manager refuses an existing unmanaged config rather than force-replacing it.
Existing private keys, included source files and known_hosts are left alone.

To add a new host declaratively, use the current Home Manager settings interface:

```nix
programs.ssh.settings."media-server" = {
  HostName = "192.168.1.50";
  User = "admin";
  IdentityFile = ["~/.ssh/sops/neo-auth"];
  IdentitiesOnly = true;
};
```

Imported Includes come first to preserve your current behaviour. OpenSSH normally
uses the first obtained value; remove a host's old imported block when migrating
that same alias into `programs.ssh.settings`. Use `lib.hm.dag.entryBefore/After`
when ordering overlapping managed Host/Match blocks matters. Do not automatically
sort or collapse your old rules.

## 7. Select which SSH private keys to encrypt

List **public** fingerprints and compare them with the importer report:

```sh
for pub in "$HOME"/.ssh/*.pub; do ssh-keygen -lf "$pub"; done
```

Your Git configuration currently expects `~/.ssh/id_gitsign_fs`; include it only
if you want SOPS to provision that signing identity. Authentication and signing
can use separate keys. Keep hardware/1Password-agent-only identities in their
agent; they need not be exported to SOPS. Check `ssh-add -L` for public agent keys.

For a new authentication identity on neo, generate it locally:

```sh
umask 077
ssh-keygen -t ed25519 -f "$HOME/.ssh/id_neo_auth" -C "fs@neo"
```

Choose a passphrase for interactive personal use. The passphrase remains required
by SSH/ssh-agent after SOPS decrypts the file. Unattended automation needs a
suitably restricted unattended credential; do not strip your personal passphrase
just to avoid a prompt.

Create the encrypted file without printing key contents, putting them in command
arguments, or writing a plaintext payload to the repository:

```sh
python3 tools/encrypt-ssh-keys.py secrets/neo.yaml \
  --key "neo-auth=$HOME/.ssh/id_neo_auth" \
  --key "gitsign=$HOME/.ssh/id_gitsign_fs"
```

Omit `gitsign` if it does not exist or you are leaving signing unchanged. This
helper intentionally refuses an existing destination. To add/edit fields later,
use `sops secrets/neo.yaml` with a trusted local editor; multiline private keys
use YAML `|` block scalars. Disable editor swap/backup/cloud sync for secret edits.
A SOPS editor session has temporary plaintext on the local machine.

Verify decryption and public fingerprints locally without printing private keys:

```sh
umask 077
verify_dir="$(mktemp -d)"
sops --decrypt --extract '["neo-auth"]' secrets/neo.yaml > "$verify_dir/identity"
ssh-keygen -y -f "$verify_dir/identity"
rm -rf "$verify_dir"
```

SSH may prompt for the original key passphrase. Compare the resulting public key with `~/.ssh/id_neo_auth.pub`. Successful decryption with the
recovery key does not prove neo was included as a recipient: also test with neo's
machine age identity (root) before activation, as described in step 8.

## 8. Enable runtime provisioning and switch

Add to `hosts/neo/configuration.nix`:

```nix
my.secrets = {
  enable = true;
  sshKeys = {
    neo-auth = { sopsFile = ../../secrets/neo.yaml; };
    gitsign = { sopsFile = ../../secrets/neo.yaml; };
  };
};
```

Again, omit gitsign if you did not encrypt it. Files appear as
`/run/secrets/ssh-neo-auth` and `/run/secrets/ssh-gitsign`, owned by fs, mode 0600.
No existing `~/.ssh/id_*` file is replaced. Decryption runs during system activation
and boot; the machine age identity must already exist.

Test the recipient before switching (the plaintext is discarded):

```sh
sops_bin="$(command -v sops)"
sudo env SOPS_AGE_KEY_FILE=/var/lib/sops-nix/age-key.txt \
  "$sops_bin" --decrypt secrets/neo.yaml > /dev/null
```

Add to the enabled `my.ssh` block in `home/fs/neo.nix`:

```nix
secretIdentities = {
  neo-auth = "/run/secrets/ssh-neo-auth";
  gitsign = "/run/secrets/ssh-gitsign";
};
signingIdentity = "gitsign"; # omit to keep your existing Git signing setup
```

This creates symlinks under `~/.ssh/sops/`. Only runtime path strings enter Nix;
private file contents are never imported. For a user-owned token, use native
`sops.secrets.<name>` options alongside this module rather than forcing it into
the SSH-specific convenience option.

Review and explicitly stage the encrypted/configuration files:

```sh
python3 tools/check-secrets.py secrets/neo.yaml
git add .sops.yaml secrets/neo.yaml files/ssh/imported/neo \
  hosts/neo/configuration.nix home/fs/neo.nix
```

Use build/switch commands from your current branch. If PR #8 is merged, use:

```sh
just darwin-build neo
just darwin-switch neo
```

This PR itself is based on main independently of PR #8. If still using main's
old recipes, they have the missing-lib staging bug identified in the audit; use
these locked-input commands directly for this first activation:

```sh
sudo nix run --inputs-from . darwin#darwin-rebuild -- switch --flake .#neo
nix run --inputs-from . home-manager -- switch --flake '.#fs@neo'
```

Switch the system first, then the home. After enrollment, `just quick-update neo`
can provision the declared secrets as part of the normal system activation once
the deployment fixes from PR #8 are present.

Check permissions and references without printing values:

```sh
ls -l "$HOME/.ssh/sops/neo-auth"
sudo ls -l /run/secrets/ssh-neo-auth
ssh -G media-server | grep -E '^(hostname|user|identityfile|identitiesonly) '
```

`ssh -G` can execute existing `Match exec` commands and resolve names; use only
trusted config. It does not prove the remote accepts your key. Test a real login
while the previous session remains open.

For Git signing, register the signing **public** key with GitHub as a signing key
and retain existing trusted signers. `my.ssh.allowedSigners` optionally manages
`~/.ssh/allowed_signers`, with entries such as
`"fabrice@fabricesemti.com ssh-ed25519 AAAA..."`. Leave it empty to keep the current
file. Back up/move any manual allowed_signers file before enabling its management.
Verify a newly signed commit with `git log -1 --show-signature`.

## 9. Authorize access on Nix-managed targets

Private keys live on the **client**; targets normally only receive the client's
public key. Do not copy neo's private key or decryption identity to a target just
to allow neo to log in.

For this repository's NixOS hosts, `userConfig.sshKeys` in `users/fs.nix` feeds
`users.users.fs.openssh.authorizedKeys.keys`. Append the complete new public
`id_neo_auth.pub` line there, retaining existing keys. Build and switch **the target**
(e.g. `just nixos-switch apoc` after PR #8), then test `ssh fs@apoc` from neo.
Only remove an old public key after every affected client/target is verified.

For another NixOS configuration, add its authorized key declaratively in that
host's repo using the same native option. It need not use SOPS to accept an SSH
public key. NixOS's generated authorized keys are separate from manual files;
audit both before assuming a removed Nix entry revoked all access.

For a Mac accepting incoming SSH, client configuration alone does not enable
Remote Login. Enable Remote Login deliberately through the target's settings, if needed. With
`my.ssh.enable = true`, you may manage public keys with
`my.ssh.authorizedKeys = ["ssh-ed25519 AAAA... fs@neo"];` on that target. Back up
and move its existing manual authorized_keys before its first Home Manager switch.
This option does not turn on incoming SSH on neo or change its firewall.

## 10. Connect non-Nix-managed targets

A non-Nix-managed server, Proxmox node, NAS or appliance does **not** need Nix
installed to be represented in your declarative Mac client configuration.

1. Generate/select neo's authentication identity as in step 7.
2. Add a `programs.ssh.settings` entry with the target's address, login user and
   `IdentityFile = ["~/.ssh/sops/neo-auth"]` (or its existing identity).
3. Install **only the public key** through the target's supported UI/API or Linux
   authorized_keys workflow. For a normal Linux account, log in with existing
   working access and append the public line to `~/.ssh/authorized_keys`; use mode
   0700 on `.ssh` and 0600 on `authorized_keys`, owned by that account. Preserve
   existing entries. From the tool shell on neo, this standard helper appends the
   key using an already-working login:

   ```sh
   ssh-copy-id -i "$HOME/.ssh/id_neo_auth.pub" existing-working-alias
   ```

   Replace the alias with the real existing connection. It needs working SSH
   authentication; use the target console if none exists. An appliance UI may
   overwrite manual files, so use its UI instead of ssh-copy-id there.
4. Verify the server's host-key fingerprint through its console/admin interface;
   do not blindly replace a changed known_hosts entry.
5. Build/switch neo's home configuration, and test login from a second terminal.
6. Keep the target in Mac SSH configuration; do not add it to `nixosConfigurations`
   unless it actually runs NixOS. Changing a target address does not provision it.

### Optional: actually manage a Linux user's configuration with Nix

For a normal supported Linux server (not an appliance), standalone Home Manager
can manage that user's files without replacing the OS. First keep existing SSH
access and a console/recovery route. Here is an example for user `admin` on an
x86_64 Debian/Ubuntu host named `legacy`:

1. Install Nix using the official installer as a normal sudo-capable user. Download
   and inspect the installer before running it:

   ```sh
   curl -fsSL https://nixos.org/nix/install -o /tmp/install-nix
   less /tmp/install-nix
   sh /tmp/install-nix --daemon
   ```

2. Start a new login shell. Enable flakes for that user:

   ```sh
   mkdir -p "$HOME/.config/nix"
   printf '%s\n' 'experimental-features = nix-command flakes' >> "$HOME/.config/nix/nix.conf"
   ```

   Merge that setting instead of duplicating it if already configured.

3. Clone this public configuration over HTTPS so first-time access does not depend
   on a private key that Nix has not provisioned yet:

   ```sh
   git clone https://github.com/fabricesemti80/infra-nix-home-machines.git
   cd infra-nix-home-machines
   git switch feat/sops-ssh-bootstrap
   ```

   Use the merged branch name instead once the PR is merged.

4. Create `home/legacy.nix` with only the desired user configuration. Do not import
   the complete workstation profile onto a server:

   ```nix
   {...}: {
     imports = [./modules/ssh.nix];
     home.username = "admin";
     home.homeDirectory = "/home/admin";
     home.stateVersion = "25.11";
     programs.home-manager.enable = true;
     my.ssh.enable = true;
     my.ssh.authorizedKeys = ["ssh-ed25519 AAAA_REPLACE_WITH_NEO_PUBLIC_KEY fs@neo"];
   }
   ```

5. Add an output alongside the existing entries in `flake.nix`:

   ```nix
   "admin@legacy" = home-manager.lib.homeManagerConfiguration {
     pkgs = import nixpkgs { system = "x86_64-linux"; };
     modules = [./home/legacy.nix];
   };
   ```

   Match the real architecture (`aarch64-linux` for ARM), username and home path.
   If you have merged PR #8's inventory-generated homes, add this standalone entry
   by merging an attrset into `homeConfigurations`, not by declaring it a second
   time. Keep legacy out of the NixOS deployment lane: it is not a NixOS system.

6. Review/stage `home/legacy.nix` and the flake edit. Build without activation:

   ```sh
   git add home/legacy.nix flake.nix
   nix run --inputs-from . home-manager -- build --flake '.#admin@legacy'
   ```

7. Keep your current SSH session open. Back up/move any manual
   `~/.ssh/authorized_keys` out of the way, retaining all existing public keys in
   the declaration if they should still work. Then switch **as admin, not root**:

   ```sh
   auth_backup="$HOME/.ssh/authorized_keys.before-home-manager.$(date +%Y%m%d-%H%M%S)"
   if [ -e "$HOME/.ssh/authorized_keys" ]; then
     mv "$HOME/.ssh/authorized_keys" "$auth_backup"
   fi
   nix run --inputs-from . home-manager -- switch --flake '.#admin@legacy'
   chmod 700 "$HOME/.ssh"
   ```

   Home Manager stores public authorized keys in the Nix store, which is fine;
   never use this mechanism for private keys. If switching fails, restore the
   backup from the open session before closing it.

8. Test a second login from neo. Only after it works should you close the old
   session. The OS still owns sshd, account permissions, SELinux policy if present,
   and the firewall; configure those through its normal tooling.

Public-key-only enrollment needs no SOPS identity on legacy. If that host also
needs private secrets, root-level provisioning through sops-nix requires NixOS or
nix-darwin; on ordinary Linux, use the sops-nix Home Manager module with a separate
user age identity and its user-service ordering instead. Do not copy this PR's
system module into a Home Manager config.

A full NixOS conversion is a different operation and can repartition disks. Follow
`docs/physical-hosts.md` only after backup and an explicit OS-migration plan.

## 11. Rotation, new machines and recovery

- New machine: generate a unique age identity, add its public recipient to the
  appropriate rule, run `sops updatekeys` on affected files, then enroll its Nix
  modules. A generated key alone cannot decrypt existing ciphertext.
- Lost machine: remove its age recipient, update affected files, revoke its SSH
  public authentication keys on targets and GitHub, and rotate any secret it could
  decrypt. Re-encryption does not revoke old Git history or copied secrets.
- Reinstall: generate a new machine identity and use the 1Password recovery
  identity to update recipients, or restore that machine's backed-up identity.
  Bootstrap through console/existing access; do not make the SSH key needed for
  the first deployment depend on that deployment's decryption succeeding.
- Recovery-key rotation: add a new recovery recipient, update every encrypted
  file and test it, then retire the old identity. Old history still exists.
- Rollback: keep the previous system/home generations and the private backup until
  tested. On the Mac, use `sudo darwin-rebuild switch --rollback` and independently
  reactivate the previous Home Manager generation if required. To return to manual
  SSH config, disable `my.ssh`, switch home, then restore your backed-up config.

## References

- https://github.com/Mic92/sops-nix#readme
- https://github.com/getsops/sops#readme
- https://nix-community.github.io/home-manager/options.xhtml#opt-programs.ssh.enable

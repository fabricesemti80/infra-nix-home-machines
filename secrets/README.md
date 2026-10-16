# Encrypted runtime secrets

Follow [the complete setup guide](../docs/sops-and-ssh.md). No real credential or
placeholder ciphertext ships with this repository. Start with one enrolled host.

Copy `.sops.yaml.example` to the repository root as `.sops.yaml`, fill real public
recipients, and create encrypted `neo.yaml`, `apoc.yaml` or `shared.yaml` files.
All payload values must be encrypted; pre-commit rejects plaintext values in YAML
files here. This is a structural guard, not proof of ciphertext authenticity:
test actual decryption locally with the intended machine key.

Do not commit age identities, plaintext private keys, decrypted `.env` files or
editor backups. The root .sops.yaml contains public recipients only.

# Reviewed SSH configurations

Run `python3 tools/import-ssh-config.py --label neo` on the Mac first.
The command is a dry run unless `--write` is supplied. It copies configuration
files only, never IdentityFile contents, and never edits ~/.ssh.

Review the output before committing it. SSH configuration can contain internal
addresses and commands with embedded credentials. External Include files are
recorded in manifest.json and remain external dependencies. Do not enable an
import until those dependencies and all relative IdentityFile paths are reviewed.

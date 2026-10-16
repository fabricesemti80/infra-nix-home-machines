# Global ignore defaults; keep agent instructions and specifications readable.
_: {
  home.file = {
    ".claudeignore".text = ''
      # Build artifacts
      node_modules/
      dist/
      build/
      target/
      .next/
      out/
      .output/
      .vercel/
      .turbo/
      .cache/
      __pycache__/
      .pytest_cache/
      .mypy_cache/
      .ruff_cache/
      .tox/
      .venv/
      .direnv/
      .devenv/
      coverage/
      .coverage
      htmlcov/
      .nyc_output/

      # Lock files (usually too large/noisy for context)
      package-lock.json
      yarn.lock
      pnpm-lock.yaml
      bun.lockb
      Cargo.lock
      poetry.lock
      Gemfile.lock

      # Logs & temp
      *.log
      *.tmp
      *.temp
      *.swp
      *.swo
      .DS_Store
      Thumbs.db

      # IDE / editor
      .vscode/
      .idea/
      *.code-workspace
      .zed/
      .nova/
      .vim/
      .nvim/

      # Nix
      result
      result-*/
      .nix-search/
      .direnv/

      # Terraform / Infra
      .terraform/
      *.tfstate
      *.tfstate.*
      .terraform.lock.hcl
      .terragrunt-cache/

      # Media / binaries
      *.png
      *.jpg
      *.jpeg
      *.gif
      *.ico
      *.svg
      *.mp4
      *.mov
      *.avi
      *.mp3
      *.wav
      *.qcow2
      *.iso
      *.img
      *.dmg
      *.pkg
      *.deb
      *.rpm
      *.zip
      *.tar.gz
      *.tar.bz2

      # Git
      .git/
      .gitignore

      # Documentation
      CHANGELOG*
      LICENSE*
      LICENSE.*
      COPYING*
      AUTHORS*
      CONTRIBUTORS*

      # Secrets
      .env
      .env.*
      *.pem
      *.key
      *.crt
      *.p12
      *.pfx
      secrets/
      secrets.*
      .secrets/
    '';

    ".codexignore".text = ''
      node_modules/
      dist/
      build/
      .git/
      .cache/
      __pycache__/
      .venv/
      *.lock
      *.log
      *.png
      *.jpg
      *.svg
      result
      .direnv/
    '';
  };
}

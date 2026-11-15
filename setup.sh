#!/usr/bin/env bash
# One-shot setup for this repo: deploy the configs and make sure a GitHub SSH
# key exists. Safe to re-run: every step checks the state it needs first.
#
#   ./setup.sh
#
# Deploys:
#   ~/.config/hypr/bindings.lua
#   ~/.config/gh/config.yml
#   ~/.gitconfig
#   ~/.ssh/config
#
# Generates ~/.ssh/id_ed25519 when missing, then prints the public key to add
# at https://github.com/settings/keys.
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_dir"

die() {
	printf 'setup: %s\n' "$*" >&2
	exit 1
}

command -v mise >/dev/null 2>&1 || die "mise not found. Install Omarchy or mise first."
command -v ssh-keygen >/dev/null 2>&1 || die "ssh-keygen not found. Install openssh."
command -v git >/dev/null 2>&1 || die "git not found."

# Files this repo owns under $HOME, relative to it.
targets=(
	.config/gh/config.yml
	.config/hypr/bindings.lua
	.config/lazygit/config.yml
	.gitconfig
	.ssh/config
)

# 1. Install the declared packages (lazygit, lazydocker, git-delta). Skips the
#    sudo prompt entirely when the set is already satisfied.
if ! mise bootstrap packages status --missing >/dev/null 2>&1; then
	printf 'Installing declared packages (needs sudo for pacman)...\n'
	mise bootstrap packages apply
fi

# 2. Clear real files out of the way, keeping a copy. mise refuses to replace
#    a path it did not deploy, and a user's existing ssh/git config is worth
#    keeping. Links that already point into this checkout are left alone.
backup_dir="$HOME/.dotfiles-share-backup/$(date +%Y%m%d-%H%M%S)"
conflicts=0
for rel in "${targets[@]}"; do
	path="$HOME/$rel"
	[ -e "$path" ] || [ -L "$path" ] || continue
	if [ -L "$path" ] && [ "$(readlink -f "$path")" = "$repo_dir/base/$rel" ]; then
		continue
	fi
	mkdir -p "$backup_dir/$(dirname "$rel")"
	mv "$path" "$backup_dir/$rel"
	printf 'backed up ~/%s -> %s/%s\n' "$rel" "$backup_dir" "$rel"
	conflicts=$((conflicts + 1))
done

# 3. Deploy the dotfile group.
mise trust --yes >/dev/null
mise dot apply --yes

# 4. Generate the GitHub SSH key when it does not exist yet.
key="$HOME/.ssh/id_ed25519"
if [ -f "$key" ]; then
	printf 'ssh key already exists, skipped: %s\n' "$key"
else
	# Use the configured email as the key comment when it is real, otherwise
	# fall back to user@host (the committed config ships placeholders).
	comment="$(git config --global user.email 2>/dev/null || true)"
	if [ -z "$comment" ] || [ "$comment" = "you@example.com" ]; then
		comment="$(id -un)@$(hostname)"
	fi
	mkdir -p "$HOME/.ssh"
	chmod 700 "$HOME/.ssh"
	ssh-keygen -q -t ed25519 -N "" -C "$comment" -f "$key"
	printf 'created ssh key: %s\n' "$key"
fi

# 5. Load the key into an agent that is already running (never start one here:
#    it would die with this script). A missing agent is fine, ssh reads the
#    key file directly.
if [ -n "${SSH_AUTH_SOCK:-}" ]; then
	ssh-add "$key" >/dev/null 2>&1 || true
fi

printf '\nPublic key (add it at https://github.com/settings/keys):\n\n'
cat "$key.pub"

cat <<'EOF'

Next steps:
  1. Add the public key above to GitHub.
  2. Set your identity in ~/.gitconfig (name and email are placeholders).
  3. Log in to the GitHub CLI: gh auth login
  4. Test the key: ssh -T git@github.com
EOF

if [ "$conflicts" -gt 0 ]; then
	printf '\nExisting files were moved to %s\n' "$backup_dir"
fi

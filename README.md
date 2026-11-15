# dotfiles-share

A small, single-machine slice of my dotfiles for **Omarchy** (Arch Linux):

| File | Lands at | What it does |
|---|---|---|
| `base/.config/hypr/bindings.lua` | `~/.config/hypr/bindings.lua` | Stock Omarchy keybindings — a clean canvas for your own |
| `base/.gitconfig` | `~/.gitconfig` | Basic git config for one account |
| `base/.ssh/config` | `~/.ssh/config` | One GitHub host block |
| `base/.config/gh/config.yml` | `~/.config/gh/config.yml` | GitHub CLI preferences (no credentials) |
| `base/.config/lazygit/config.yml` | `~/.config/lazygit/config.yml` | lazygit diffs rendered by delta |

`setup.sh` deploys all five, installs `lazydocker` and `git-delta`
(`lazygit` already ships with Omarchy), and creates your GitHub SSH key if
missing.

The keybindings file is the stock Omarchy override template, unmodified: every
Omarchy default works, and you add or change bindings in one place without
editing the defaults. Omarchy upgrades keep improving the defaults while your
overrides stay yours.

## Install

Requires [Omarchy](https://omarchy.org) (which brings `mise`), `git`, and
`openssh`.

```sh
git clone https://github.com/Dahep/dotfiles-share.git ~/dotfiles-share
cd ~/dotfiles-share
./setup.sh
```

The script:

1. Installs the declared packages `lazydocker` and `git-delta` with
   `mise bootstrap packages apply` (skipped when they are already present;
   `lazygit` comes with Omarchy).
2. Moves any existing real file out of the way to
   `~/.dotfiles-share-backup/<timestamp>/` (mise refuses to replace files it
   did not deploy).
3. Symlinks the configs into `$HOME` with `mise dot apply`.
4. Generates `~/.ssh/id_ed25519` if it does not exist yet and prints the public
   key.
5. Loads the key into a running ssh-agent, if there is one.

It is safe to re-run: package state, deployed links, the backup step, and the
key check all skip work that is already done. Only the five files listed at the
top are touched.

Prefer to do it by hand? `mise trust`, `mise bootstrap packages apply`, then
`mise dot apply --yes`, and `ssh-keygen -t ed25519 -C "you@example.com"` for
the key.

Check the result and remove the links later:

```sh
mise dot status --missing   # exit 0 means everything is deployed
mise dot unapply            # remove the deployed links
```

## Finish setup

1. **Set your git identity** — edit `~/.gitconfig` (or `base/.gitconfig` and
   re-apply). The committed values are placeholders:

   ```ini
   [user]
       name = Your Name
       email = you@example.com
   ```

2. **Log in to the GitHub CLI** — `./setup.sh` printed your public key, but the
   easiest path is to let `gh` upload it while you authenticate:

   ```sh
   gh auth login
   ```

   Choose **GitHub.com** → **SSH** as the git protocol. When it offers to
   upload a public key, pick `~/.ssh/id_ed25519.pub`. Authenticate in the
   browser when prompted. The token is stored in your OS keyring, never in this
   repo.

   ```sh
   gh auth status            # shows the account and token scopes
   ```

   Already logged in, or prefer not to let `gh` touch the key? Add it yourself
   (next step).

3. **Add the generated SSH key to your GitHub account** — `./setup.sh` created
   `~/.ssh/id_ed25519`; its public half is what GitHub needs.

   With the CLI (already logged in):

   ```sh
   gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)"
   ```

   Or in the browser: copy the key and paste it at
   <https://github.com/settings/keys> → **New SSH key**:

   ```sh
   cat ~/.ssh/id_ed25519.pub
   ```

4. **Test the key**:

   ```sh
   ssh -T git@github.com     # should greet you by username
   ```

   The repo's `~/.ssh/config` points at `~/.ssh/id_ed25519`. Using a different
   key name? Change `IdentityFile` there. Want a passphrase on the key? Run
   `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519` yourself before `./setup.sh`.

## Add your own keybindings

Bindings live in `base/.config/hypr/bindings.lua`. The stock file is only
comments; uncomment or add lines:

```lua
-- Add a binding.
o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Replace a default (same key, your command).
o.rebind("SUPER + SHIFT + F", "File manager", { launch = "flea" })

-- Disable a default.
hl.unbind("SUPER + SHIFT + B")
```

See every active binding and its description:

```sh
omarchy menu keybindings --print
```

Reload Hyprland to pick up changes (Super+Esc, then Relaunch), or edit the
deployed file directly — it is a symlink into this checkout, so saving is the
same as editing the repo.

## Track more configs

The repo takes whatever you put under `base/` and deploys it to the same path
under `$HOME`. To start tracking a live file or directory:

```sh
# one file
cp ~/.config/foo/bar.toml base/.config/foo/bar.toml
git add base/.config/foo/bar.toml

# a whole directory
cp -r ~/.config/foo base/.config/foo
git add base/.config/foo

mise dot apply --yes
mise dot status --missing   # exit 0 = deployed
```

`git add` is not optional: the group uses `manifest = "git"`, so deployment
reads Git's index and an untracked file stays invisible.

If the target already exists as a real file, `mise dot apply` refuses to
replace it. Move it into `~/.dotfiles-share-backup/` first (or let `./setup.sh`
do that on its next run). `--force` overwrites without a backup, so avoid it.

To stop deploying something, remove it from the repo and prune the leftover
link:

```sh
git rm base/.config/foo/bar.toml
mise dot apply --prune
```

### Packages

Declare tools in `mise.toml` and apply them:

```toml
[bootstrap.packages]
"pacman:ripgrep" = "latest"
```

```sh
mise bootstrap packages apply
mise bootstrap packages status --missing   # exit 0 = installed
```

Official Arch repositories only (`pacman:` keys). An AUR-only package needs a
different route, such as `yay -S --needed` by hand or a `github:` tool entry.

## How deployment works

`mise.toml` declares one home-relative group, `base`. Every path under
`base/` is deployed at the same path under `~`, and files are deployed from
Git's index — so `git add` a file before `mise dot apply` sees it. Handy
commands:

```sh
mise dot diff          # what apply would change
mise dot apply --yes
mise dot status --missing
```

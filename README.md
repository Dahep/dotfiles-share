# dotfiles-share

A small, single-machine slice of my dotfiles for **Omarchy** (Arch Linux):

| File | Lands at | What it does |
|---|---|---|
| `base/.config/hypr/bindings.lua` | `~/.config/hypr/bindings.lua` | Stock Omarchy keybindings — a clean canvas for your own |
| `base/.gitconfig` | `~/.gitconfig` | Basic git config for one account |
| `base/.ssh/config` | `~/.ssh/config` | One GitHub host block |
| `base/.config/gh/config.yml` | `~/.config/gh/config.yml` | GitHub CLI preferences (no credentials) |

The keybindings file is the stock Omarchy override template, unmodified: every
Omarchy default works, and you add or change bindings in one place without
editing the defaults. Omarchy upgrades keep improving the defaults while your
overrides stay yours.

## Install

Requires [Omarchy](https://omarchy.org) (which brings `mise`) and `git`.

```sh
git clone https://github.com/Dahep/dotfiles-share.git ~/dotfiles-share
cd ~/dotfiles-share
mise trust              # once per checkout
mise dot apply --yes
```

`mise dot apply` symlinks each file into place. If one of the targets already
exists as a real file, mise refuses to overwrite it — back the file up (or
delete it) and run the apply again. Nothing here touches anything else in
`$HOME`.

Check the result and remove the links later:

```sh
mise dot status --missing   # exit 0 means everything is deployed
mise dot unapply            # remove the deployed links
```

## After installing

1. **Git identity** — edit `~/.gitconfig` (or `base/.gitconfig` and re-apply):

   ```ini
   [user]
       name = Your Name
       email = you@example.com
   ```

2. **SSH key for GitHub** — create one and add the public half at
   <https://github.com/settings/keys>:

   ```sh
   ssh-keygen -t ed25519 -C "you@example.com"
   ssh -T git@github.com     # should greet you by username
   ```

   The repo's `~/.ssh/config` points at `~/.ssh/id_ed25519`. Using a different
   key name? Change `IdentityFile` there.

3. **GitHub CLI** — log in once; `gh auth login` stores the token in your OS
   keyring, not in this repo:

   ```sh
   gh auth login
   gh auth status
   ```

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

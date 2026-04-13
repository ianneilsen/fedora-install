# Switching from zsh to bash on macOS (iTerm2)

macOS ships with ancient bash 3.2 at `/bin/bash` (Apple froze it GPLv2 version).
This guide assumes Apple Silicon (`/opt/homebrew`). 

Check with `which -a bash`.

## 1. Install modern bash via Homebrew

```bash
brew install bash
```

Verify the install:

```bash
/opt/homebrew/bin/bash --version
# Should show GNU bash, version 5.x
```

## 2. Add to list of allowed shells

macOS only lets you set login shells that are listed in `/etc/shells`.

```bash
echo "/opt/homebrew/bin/bash" | sudo tee -a /etc/shells
```

Confirm it's in there:

```bash
cat /etc/shells
```

## 3. Change your login shell

```bash
chsh -s /opt/homebrew/bin/bash
```
You'll be prompted for password. This updates your user record in Directory Services — it persists across reboots and applies to every new terminal.

## 4. Tell iTerm2 to use it

iTerm2 respects your login shell by default, but double-check:

1. **iTerm2 → Settings → Profiles → General → Command**
2. Set to **Login shell** (not "Custom shell")

Close all iTerm2 windows and open a fresh one (⌘Q to fully quit, then reopen).

## 5. Verify

```bash
echo $SHELL
# /opt/homebrew/bin/bash

bash --version
# GNU bash, version 5.2.x
```

If `$SHELL` still shows zsh, you're in a stale session — fully quit iTerm2 (⌘Q) and reopen.

## 6. Create your `~/.bash_profile`

macOS terminals start as **login shells**, which read `~/.bash_profile` (not `~/.bashrc` like Linux does for interactive non-login shells). The standard trick is to source `.bashrc` from `.bash_profile` so your Fedora `.bashrc` just works:

```bash
cat > ~/.bash_profile <<'EOF'
# Source .bashrc for interactive shell config (Linux parity)
[ -f ~/.bashrc ] && source ~/.bashrc
EOF
```

Now drop your Fedora `.bashrc` into `~/.bashrc` and everything — aliases, prompt, PATH exports — works the same on both machines.

## 7. Silence the zsh deprecation nag (one-off)

If you see `The default interactive shell is now zsh` anywhere, add this to shut it up:

```bash
export BASH_SILENCE_DEPRECATION_WARNING=1
```

Put it in `~/.bashrc` so it's set everywhere.

## Rolling back

If you change your mind:

```bash
chsh -s /bin/zsh
```

Restart the terminal.

## Heads-up

Some macOS-specific completions and tools assume zsh (Apple's own docs, some brew formulae output). 99% of the time it doesn't matter, but if you hit something weird, that's usually why.

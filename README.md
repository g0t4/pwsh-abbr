## Abbr module

This is my implementation of expanding aliases (or abbreviations as in fish shell), to compress keystrokes for common commands into aliases that expand, before execution, into the full command. I created this initially so when recording courses I wasn't hiding commands behind traditional aliases, so viewers can follow along.

## Usage

```pwsh

Install-PSResource Abbr

Import-Module Abbr # optional, using `ealias` function triggers module to be loaded too

# examples
ealias gst 'git status'
ealias dcpsa 'docker container ps -a'
ealias dcri 'docker container run --rm -i -t'
ealias kgp 'kubectl get pods'

```

Visit my [dotfiles](https://github.com/g0t4/dotfiles) repo for my private version [_alias-helpers.ps1](https://github.com/g0t4/dotfiles/blob/master/pwsh/helpers/load_first/_alias-helpers.ps1) of this module AND for hundreds of ealias examples across a variety of commands. By the way, most updates will happen in my private version and only occasionally merged back into this public module/repo, that way this version is stable.

## Videos

I published a series of videos to explain how I set this up in `zsh`, `powershell` and `fish` shells:
- [rationale](https://youtu.be/YE2llYDwQI0)
- [using AutoHotKey instead of `ealias`](https://youtu.be/Gpfw3grNvwQ)
- [zsh impl](https://youtu.be/R3Kq2FSKUw8)
- [fish impl - abbr func](https://youtu.be/wfqQmrv3YeM)

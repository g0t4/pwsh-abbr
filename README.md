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

Visit my [dotfiles](https://github.com/g0t4/dotfiles) repo for my private version of this module AND for hundreds of ealias examples across a variety of commands.
# Ghostty actions

Update Ghostty termcaps for remote host push:

(From a Ghostty terminal)

```sh
infocmp -x | grep -v '^#' > $DOTFILES_SRC_HOME/ghostty/xterm-ghostty.terminfo
```

# Setup fzf
# ---------
# install.sh clones fzf into ~/.fzf and runs its installer with --no-update-rc,
# so this file (not the generated ~/.fzf.bash) is what wires it into the shell.
if [[ -d $HOME/.fzf/bin && ":$PATH:" != *":$HOME/.fzf/bin:"* ]]; then
  export PATH="${PATH:+${PATH}:}$HOME/.fzf/bin"
fi

# Key bindings and completion (fzf >= 0.48)
if [[ $- == *i* ]] && command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --bash)"
fi

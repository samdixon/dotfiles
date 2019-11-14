# Setup fzf
# ---------
if [[ ! "$PATH" == */Users/sdixon/.fzf/bin* ]]; then
  export PATH="${PATH:+${PATH}:}/Users/sdixon/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/Users/sdixon/.fzf/shell/completion.bash" 2> /dev/null

# Key bindings
# ------------
source "/Users/sdixon/.fzf/shell/key-bindings.bash"

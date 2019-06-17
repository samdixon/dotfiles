# Mac and Linux Path exports
case `uname` in
  Darwin)
  export PATH=/usr/local/bin:$PATH
  export ZSH=$HOME/.oh-my-zsh
  ;;
  Linux)
  export PATH=$PATH:/home/sdixon/.local/bin
  ;;
esac

# Oh My ZSH Specific Settings
ZSH_THEME=""
ZSH=~/.oh-my-zsh
source $ZSH/oh-my-zsh.sh

# Source Pure Prompt after sourcing oh-my-zsh
autoload -U promptinit; promptinit
prompt pure

# Function Path
fpath=(~/.zsh/completion $fpath)

# Personal Functions
function quickCommit {
  git add *
  git add -u
  git commit -m "quick commit"
  git push origin master
}

function push {
  git push origin $@
}

# OS Specific Functions
case `uname` in
Linux)
	runUpdates() {
		sudo apt update && sudo apt upgrade -y
	}
;;
esac

# Aliases
alias awsume=". awsume"
alias ls='lsd'
alias ll='lsd -ll'
alias cat='bat'

# fzf mac and linux settings
case `uname` in
Darwin)
  _has() {
    return $( whence $1 >/dev/null )
  }

  # Returns whether the given statement executed cleanly. Try to avoid this
  # because this slows down shell loading.
  _try() {
    return $( eval $* >/dev/null 2>&1 )
  }

  # Returns whether the current host type is what we think it is. (HOSTTYPE is
  # set later.)
  _is() {
    return $( [ "$HOSTTYPE" = "$1" ] )
  }

  # Returns whether out terminal supports color.
  _color() {
    return $( [ -z "$INSIDE_EMACS" ] )
  }

  # fzf via Homebrew
  if [ -e /usr/local/opt/fzf/shell/completion.zsh ]; then
    source /usr/local/opt/fzf/shell/key-bindings.zsh
    source /usr/local/opt/fzf/shell/completion.zsh
  fi

  # fzf via local installation
  if [ -e ~/.fzf ]; then
    _append_to_path ~/.fzf/bin
    source ~/.fzf/shell/key-bindings.zsh
    source ~/.fzf/shell/completion.zsh
  fi

  # fzf + ag configuration
  if _has fzf && _has ag; then
    export FZF_DEFAULT_COMMAND='ag --nocolor -g ""'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_DEFAULT_OPTS='
    --color fg:242,bg:236,hl:65,fg+:15,bg+:239,hl+:108
    --color info:108,prompt:109,spinner:108,pointer:168,marker:168
    '
  fi
  ;;
  Linux)
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
  ;;
esac

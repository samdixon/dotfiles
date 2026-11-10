# env
export PATH="/opt/homebrew/bin:$PATH:$HOME/bin:$HOME/.npm-packages/bin:$HOME/.local/bin:/Applications/Sublime Text.app/Contents/SharedSupport/bin:/Applications/Postgres.app/Contents/Versions/latest/bin"
export EDITOR=vim
export BASH_SILENCE_DEPRECATION_WARNING=1

#alias
alias clcopy='tail -n 1 | tee >(pbcopy)'
alias ls='ls -G'

# prompt
PS1=$'\[\033[01;95m\]\u@\h\[\033[00m\]: \[\033[01;34m\]\w\n\[\033[00m\]$ '

# pyenv
if [ -d "$HOME/.pyenv" ]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PATH:$PYENV_ROOT/bin"
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi

# nvm
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    \. "$NVM_DIR/nvm.sh"  # This loads nvm
fi
if [ -s "$NVM_DIR/bash_completion" ]; then
    \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

# shell completions
[ -x "$HOME/.local/bin/aws_completer" ] && complete -C "$HOME/.local/bin/aws_completer" aws

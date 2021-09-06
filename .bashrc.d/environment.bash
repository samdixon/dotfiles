# env
export PATH="/opt/homebrew/bin:$PATH:$HOME/bin:$HOME/.npm-packages/bin:$HOME/.local/bin"
export EDITOR=nvim
export BASH_SILENCE_DEPRECATION_WARNING=1
export notes_dir="/Users/samdixon/sjd/notes"
#alias
alias vim='nvim'
alias a='. awsume'
alias awsume='. awsume'
alias awesume='. awsume'
alias ls='ls -G'
# prompt
PS1=$'\[\033[01;95m\]\u@\h\[\033[00m\]: \[\033[01;34m\]\w\n\[\033[00m\]$ '
# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PATH:$PYENV_ROOT/bin"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# shell completions
[ -f /usr/local/bin/aws_completer ] && complete -C '/usr/local/bin/aws_completer' aws

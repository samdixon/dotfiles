[ -f ~/.bashrc.d/defaults ] && source ~/.bashrc.d/defaults
[ -f ~/.bashrc.d/functions.bash ] && source ~/.bashrc.d/functions.bash
[ -f ~/.bashrc.d/environment.bash ] && source ~/.bashrc.d/environment.bash
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
[ -f ~/.bashrc.d/git-completion.bash ] && source ~/.bashrc.d/git-completion.bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
[ -f "$HOME/.deno/env" ] && . "$HOME/.deno/env"
DENO_COMPLETIONS="$HOME/.local/share/bash-completion/completions/deno.bash"
[ -f "$DENO_COMPLETIONS" ] && source "$DENO_COMPLETIONS"

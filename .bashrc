[ -f ~/.bashrc.d/defaults ] && source ~/.bashrc.d/defaults
[ -f ~/.bashrc.d/functions.bash ] && source ~/.bashrc.d/functions.bash
[ -f ~/.bashrc.d/environment.bash ] && source ~/.bashrc.d/environment.bash
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
[ -f ~/.git-completion.bash ] && source ~/.git-completion.bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
. "/Users/sdixon/.deno/env"
source /Users/sdixon/.local/share/bash-completion/completions/deno.bash

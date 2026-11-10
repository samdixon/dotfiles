[ -f ~/.bashrc.d/defaults ] && source ~/.bashrc.d/defaults
[ -f ~/.bashrc.d/functions.bash ] && source ~/.bashrc.d/functions.bash
[ -f ~/.bashrc.d/environment.bash ] && source ~/.bashrc.d/environment.bash
[ -f ~/.bashrc.d/fzf.bash ] && source ~/.bashrc.d/fzf.bash
[ -f ~/.bashrc.d/git-completion.bash ] && source ~/.bashrc.d/git-completion.bash
[ -f ~/.bashrc.d/project.bash ] && source ~/.bashrc.d/project.bash
[ -f ~/.bashrc.d/assume.sh ] && source ~/.bashrc.d/assume.sh

[ -f "$HOME/.deno/env" ] && . "$HOME/.deno/env"
DENO_COMPLETIONS="$HOME/.local/share/bash-completion/completions/deno.bash"
[ -f "$DENO_COMPLETIONS" ] && source "$DENO_COMPLETIONS"

if [ -f ~/.bashrc ]; then
	source ~/.bashrc
fi
export PATH="/opt/homebrew/opt/node@16/bin:$PATH"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.bash 2>/dev/null || :
. "/Users/sdixon/.deno/env"
source /Users/sdixon/.local/share/bash-completion/completions/deno.bash

alias assume=". assume"

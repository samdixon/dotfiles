#        \   /
#        .\-/.
#    /\ ()   ()
#   /  \/~---~\.-~^-.
#.-~^-./   |   \---.
#     {    |    }   \
#   .-~\   |   /~-.
#  /    \  A  /    \
#        \/ \/

alias nd='terminal-notifier -title "Terminal" -message "Done with task! Exit status: $?"'

alias runmake='$(cat Makefile | grep : | cut -d ":" -f1 | awk '\''{print "make " $0}'\'' - | fzf)'

# Open a folder in the Claude desktop app
# ---------------------------------------
# cowork [dir]  -- new Cowork session in dir (default: .)
# ccode [dir]   -- new Claude Code session in dir (default: .)
_claude_open() {
  local mode=$1 name=$2; shift 2
  if [ $# -gt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "usage: $name [directory]" >&2
    return 1
  fi
  local dir=${1:-.}
  if [ ! -d "$dir" ]; then
    echo "$name: not a directory: $dir" >&2
    return 1
  fi
  dir=$(cd "$dir" && pwd) || return 1
  local enc
  enc=$(osascript -l JavaScript -e 'function run(a){return encodeURIComponent(a[0])}' "$dir")
  open "claude://$mode/new?folder=$enc"
}

cowork() { _claude_open cowork cowork "$@"; }
ccode()  { _claude_open code   ccode  "$@"; }

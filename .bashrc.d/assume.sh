# Shell wrapper for assume.py. A child process can't change its parent's
# environment, so this function runs the script and evals the exports it prints.
#
# Needs assume.py installed as ~/bin/assume (by the assume repo's install.sh).
#
# Usage:
#   assume 123456789012              # export creds for the default role
#   assume 123456789012 -r us-west-2 # also set AWS_REGION / AWS_DEFAULT_REGION
#   assume 123456789012 -c           # also open the console in your browser
#   assume --clear                   # unset the assumed creds

# Use assume.py next to this file (sourced from the repo), else the installed copy.
_ASSUME_PY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assume.py"
[ -f "$_ASSUME_PY" ] || _ASSUME_PY="$HOME/bin/assume"

# An `assume` alias would be expanded inside the definition below (syntax error)
# and would shadow the function when called.
unalias assume 2>/dev/null

assume() {
    if [ ! -f "$_ASSUME_PY" ]; then
        echo "assume: $_ASSUME_PY not found; run install.sh from the assume repo" >&2
        return 1
    fi
    local out
    out="$(uv run --quiet --script "$_ASSUME_PY" "$@")" || return
    eval "$out"
}

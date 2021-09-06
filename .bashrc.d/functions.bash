# Note functions
notedir="$HOME/Dropbox/notes"
function _open_notes() {
    if [ -z ${1+x} ]; then
        ranger $notedir
    else
        vim "$notedir/$1.md"
    fi
}
alias notes="_open_notes"

# Other
function pubip() {
    curl "ifconfig.co"
}

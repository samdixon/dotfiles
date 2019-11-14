# Note functions
notedir="$HOME/Dropbox/notes"

function _open_notes() {
    cd $notedir
    if [ -z ${1+x} ]; then
        nvim
    else
        nvim "$1.md"
    fi
}

function _list_notes() {
    ls -la $notedir | awk '{print $9}' | tail -n +4 | awk '{split($0,a,"."); print a[1]}'
}

function _create_note() {
	touch "$notedir/$1.md"
	echo "created file $1"
}

function _delete_note() {
    rm "$notedir/$1.md"
    echo "removed file $1"
}

function _move_note() {
    mv "$notedir/$1.md" "$notedir/$2.md"
    echo "renamed file $1 to $2"
}

function _serve_notes() {
    open http://localhost:3000
    mg $notedir/
}

# Note Alias
alias cnote="_create_note"
alias dnote="_delete_note"
alias mnote="_move_note"
alias lnote="_list_notes"
alias snote="_serve_notes"
alias notes="_open_notes"

# Azure Functions
function _az_login() {
    az login
}

function _az_vm_start() {
    az vm start --name "sdixon-remote" --resource-group "sdixon-remote-rg"
}

function _az_get_vm_ip() {
    az network public-ip show --name "sdixon-remote-ip" --resource-group "sdixon-remote-rg" | grep "ipAddress"
}

function az_vm_up() {
    _az_login
    _az_vm_start
    _az_get_vm_ip
}

# samalias 
alias add="git add"
alias commit="git commit"
alias status="git status"
alias gdiff="git diff"
alias pom="git push origin master"
alias vim="nvim"
alias ..="cd .."
alias ...="cd ../.."
alias ~="cd ~"

# Custom Functions
function macKillDNS() {
	sudo killall -HUP mDNSResponder
	echo "Flushed DNS Successfully - Unless I threw an error message ;)"
}

function pubip() {
    curl "ifconfig.co"
}

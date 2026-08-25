#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/.dotfiles"
REPO="https://github.com/samdixon/dotfiles"
STAMP="$(date +%Y%m%d%H%M%S)"

# top-level entries that are never linked into $HOME.
# sjd.terminal is imported by hand: Terminal > Settings > Profiles > Import.
NO_LINK=(.git .gitignore install.sh README.md LICENSE sjd.terminal)
# directories we recurse into and link file-by-file, because $HOME's copy is
# shared with other tools and must not be replaced wholesale
RECURSE=(.config Library)

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }

contains() { local n=$1; shift; local x; for x in "$@"; do [[ $x == "$n" ]] && return 0; done; return 1; }

sync_repo() {
	if [[ -d $DOTFILES/.git ]]; then
		log "updating $DOTFILES"
		git -C "$DOTFILES" pull --ff-only </dev/null || warn "pull failed, using working copy as-is"
	else
		log "cloning $REPO"
		git clone "$REPO" "$DOTFILES" </dev/null
	fi
}

# The README installs this with `curl ... | bash`, which makes stdin the script
# itself. Anything that reads stdin -- the homebrew installer, fzf's install,
# a sudo password prompt -- eats the rest of the script, and bash then resumes
# parsing at a random offset and dies on a dangling `fi`. So: if we're not
# running from a real file, land the repo on disk and re-exec from there.
if [[ ! -f ${BASH_SOURCE[0]:-} && -z ${DOTFILES_REEXEC:-} ]]; then
	sync_repo
	log "re-executing from $DOTFILES/install.sh (was reading from a pipe)"
	DOTFILES_REEXEC=1 exec bash "$DOTFILES/install.sh" "$@"
fi

# ---------------------------------------------------------------- symlinks ---

# link <target-relative-to-$HOME> <dest-abs>
link() {
	local target=$1 dest=$2
	if [[ -L $dest ]]; then
		[[ "$(readlink "$dest")" == "$target" ]] && return 0
		rm -f "$dest"
	elif [[ -e $dest ]]; then
		warn "backing up existing $dest -> $dest.bak.$STAMP"
		mv "$dest" "$dest.bak.$STAMP"
	fi
	mkdir -p "$(dirname "$dest")"
	ln -s "$target" "$dest"
	log "linked ${dest#"$HOME"/} -> $target"
}

link_tree() {
	local dir=$1 rel
	# Earlier versions of this script linked ~/.config itself at the top level.
	# Left in place, every path below it resolves back into the repo and we'd
	# end up moving the repo's own files aside and linking them to themselves.
	# Drop the legacy whole-directory link and rebuild it as a real directory.
	if [[ -L $HOME/$dir ]]; then
		# resolve both sides: $HOME or $TMPDIR may contain a symlinked component
		local have want
		have=$(cd -P "$HOME/$dir" 2>/dev/null && pwd) || have=
		want=$(cd -P "$DOTFILES/$dir" && pwd)
		if [[ -n $have && $have == "$want" ]]; then
			warn "replacing legacy whole-directory link ~/$dir with per-file links"
			rm -f "$HOME/$dir"
		else
			warn "~/$dir is a symlink elsewhere, leaving it alone"
			return 0
		fi
	fi
	mkdir -p "$HOME/$dir"
	while IFS= read -r -d '' rel; do
		rel=${rel#./}
		# absolute target: a relative one would resolve against the link's own
		# directory, not $HOME, once we're more than one level deep
		link "$DOTFILES/$dir/$rel" "$HOME/$dir/$rel"
	done < <(cd "$DOTFILES/$dir" && find . -type f -print0)
}

sync_repo
cd "$DOTFILES"

for f in .??* *; do
	[[ -e $f ]] || continue
	contains "$f" "${NO_LINK[@]}" && continue
	if contains "$f" "${RECURSE[@]}"; then
		link_tree "$f"
	else
		link ".dotfiles/$f" "$HOME/$f"
	fi
done

# ---------------------------------------------------------------------- fzf ---

if [[ ! -d $HOME/.fzf ]]; then
	log "installing fzf"
	git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf" </dev/null
fi
# .bashrc.d/fzf.bash does our own sourcing, so don't let fzf edit the rc files
"$HOME/.fzf/install" --key-bindings --completion --no-update-rc </dev/null >/dev/null

# -------------------------------------------------------------------- macos ---

if [[ "$OSTYPE" == "darwin"* ]]; then
	# the top of this block is personal modifications,
	# after dock settings, most are plucked straight from mathias bynens setup
	# https://github.com/mathiasbynens/dotfiles/blob/main/.macos

	# a few settings I always adjust that are not captured here
	# and need to manually configured:
	#  - f1-f12 keys -> normal f keys
	#  - caps lock -> control
	#  - keyboard navigation to move between controls
	#    settings -> keyboard -> shortcuts -> ''Use keyboard ... controls'
	#  - night shift always on

	sudo -v
	# keep the sudo timestamp alive for the rest of the run
	while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

	if [[ ! -x /opt/homebrew/bin/brew ]]; then
		log "installing homebrew"
		NONINTERACTIVE=1 /bin/bash -c \
			"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/null
	fi
	# needed on a fresh install: brew isn't on PATH yet in this shell
	eval "$(/opt/homebrew/bin/brew shellenv)"

	SHELL_PATH="/opt/homebrew/bin/bash"
	if [[ ! -x $SHELL_PATH ]]; then
		log "installing bash"
		brew install bash </dev/null
	fi
	if ! grep -qxF "$SHELL_PATH" /etc/shells; then
		log "adding $SHELL_PATH to /etc/shells"
		echo "$SHELL_PATH" | sudo tee -a /etc/shells >/dev/null
	fi
	if [[ "$(dscl . -read "/Users/$USER" UserShell | awk '{print $2}')" != "$SHELL_PATH" ]]; then
		log "setting login shell to $SHELL_PATH"
		sudo chsh -s "$SHELL_PATH" "$USER"
	fi

	# Set a pretty fast keyboard repeat rate
	defaults write NSGlobalDomain KeyRepeat -int 2
	defaults write NSGlobalDomain InitialKeyRepeat -int 15

	# cmd + click drag window similar to x11
	defaults write -g NSWindowShouldDragOnGesture -bool true

	# remove all .DS_store files which hold information about finder window display
	# only removing for user dir. ~/Library and friends are TCC-protected, so
	# prune them instead of drowning the run in "Operation not permitted".
	log "clearing .DS_Store files under $HOME"
	find "$HOME" \
		\( -path "$HOME/Library" \
		-o -path "$HOME/.Trash" \
		-o -path "$HOME/.dotfiles/.git" \
		-o -name "*.photoslibrary" \
		-o -name "*.sparsebundle" \
		\) -prune \
		-o -name ".DS_Store" -type f -print0 2>/dev/null \
		| xargs -0 rm -f || true

	# then set finder to use list view by default
	defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

	# Dock position, hiding, size
	defaults write com.apple.dock orientation -string "left"
	defaults write com.apple.dock autohide -bool true
	defaults write com.apple.dock tilesize -int 36

	# always show scrollbar
	defaults write NSGlobalDomain AppleShowScrollBars -string "Always"

	# scroll direction
	defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

	# Disable press-and-hold for keys in favor of key repeat
	defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

	# Require password immediately after sleep or screen saver begins
	defaults write com.apple.screensaver askForPassword -int 1
	defaults write com.apple.screensaver askForPasswordDelay -int 0

	# Finder: allow quitting via ⌘ + Q; doing so will also hide desktop icons
	defaults write com.apple.finder QuitMenuItem -bool true

	# Finder: disable window animations and Get Info animations
	defaults write com.apple.finder DisableAllAnimations -bool true

	# Set Home as the default location for new Finder windows
	defaults write com.apple.finder NewWindowTarget -string "PfHm"
	defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

	# Show icons for hard drives, servers, and removable media on the desktop
	defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
	defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
	defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
	defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

	# Finder: show all filename extensions
	defaults write NSGlobalDomain AppleShowAllExtensions -bool true

	# Finder: show status bar
	defaults write com.apple.finder ShowStatusBar -bool true

	# Finder: show path bar
	defaults write com.apple.finder ShowPathbar -bool true

	# Display full POSIX path as Finder window title
	defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

	# Keep folders on top when sorting by name
	defaults write com.apple.finder _FXSortFoldersFirst -bool true

	# When performing a search, search the current folder by default
	defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

	# Disable the warning when changing a file extension
	defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

	# Enable spring loading for directories
	defaults write NSGlobalDomain com.apple.springing.enabled -bool true

	# Remove the spring loading delay for directories
	defaults write NSGlobalDomain com.apple.springing.delay -float 0

	# Change minimize/maximize window effect
	defaults write com.apple.dock mineffect -string "scale"

	# Minimize windows into their application’s icon
	defaults write com.apple.dock minimize-to-application -bool true

	# Show indicator lights for open applications in the Dock
	defaults write com.apple.dock show-process-indicators -bool true

	# Wipe all (default) app icons from the Dock
	# This is only really useful when setting up a new Mac, or if you don’t use
	# the Dock to launch apps.
	defaults write com.apple.dock persistent-apps -array

	# Show only open applications in the Dock
	defaults write com.apple.dock static-only -bool true

	# Don’t animate opening applications from the Dock
	defaults write com.apple.dock launchanim -bool false

	# Don’t show recent applications in Dock
	defaults write com.apple.dock show-recents -bool false

	# Disable send and reply animations in Mail.app
	defaults write com.apple.mail DisableReplyAnimations -bool true
	defaults write com.apple.mail DisableSendAnimations -bool true

	# Copy email addresses as `foo@example.com` instead of `Foo Bar <foo@example.com>` in Mail.app
	defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

	# Add the keyboard shortcut ⌘ + Enter to send an email in Mail.app
	defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Send" "@\U21a9"

	# Display emails in threaded mode, sorted by date (oldest at the top)
	defaults write com.apple.mail DraftsViewerAttributes -dict-add "DisplayInThreadedMode" -string "yes"
	defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortedDescending" -string "yes"
	defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortOrder" -string "received-date"

	# Disable inline attachments (just show the icons)
	defaults write com.apple.mail DisableInlineAttachmentViewing -bool true

	# Disable automatic spell checking
	defaults write com.apple.mail SpellCheckingBehavior -string "NoSpellCheckingEnabled"

	# defaults writes don't take effect until the app restarts
	for app in Dock Finder SystemUIServer; do
		killall "$app" >/dev/null 2>&1 || true
	done
fi

log "done. open a new shell to pick everything up."

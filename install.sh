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

# `defaults write` can fail for reasons that shouldn't sink the whole run
# (sandboxed app containers, keys Apple has locked down). Warn and carry on.
FAILED=0
set_default() {
	local host=()
	if [[ $1 == -currentHost ]]; then host=(-currentHost); shift; fi
	if ! defaults ${host[@]+"${host[@]}"} write "$@" 2>/dev/null; then
		warn "could not write: defaults ${host[*]-} write $*"
		FAILED=$((FAILED + 1))
	fi
}

# current value of a default, empty if unset
get_default() { defaults read "$@" 2>/dev/null || true; }

# fingerprint of the preference domains whose apps we'd have to restart, so a
# re-run that changes nothing doesn't bounce the Dock and Finder
prefs_state() {
	local d
	for d in "$@"; do defaults export "$d" - 2>/dev/null | cksum; done
}

# Ask for sudo only when a step actually needs it, and only once.
SUDO_READY=
KEEPALIVE_PID=
need_sudo() {
	[[ -n $SUDO_READY ]] && return 0
	log "administrator access needed: $*"
	sudo -v
	SUDO_READY=1
	# keep the sudo timestamp alive for the rest of the run
	while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
	KEEPALIVE_PID=$!
}
# For optional steps: same as need_sudo, but a refused or unavailable password
# prompt skips the step instead of ending the run.
try_sudo() {
	[[ -n $SUDO_READY ]] && return 0
	# no cached credentials and no terminal to prompt on: nothing to try
	sudo -n true 2>/dev/null || { : >/dev/tty; } 2>/dev/null || return 1
	sudo -v || return 1
	need_sudo "$@"
}

trap '[[ -n $KEEPALIVE_PID ]] && kill "$KEEPALIVE_PID" 2>/dev/null || true' EXIT

# On a fresh Mac /usr/bin/git is a stub that pops up the Command Line Tools
# installer and exits non-zero, so make sure the tools exist before any git.
ensure_git() {
	[[ "$OSTYPE" == "darwin"* ]] || return 0
	xcode-select -p >/dev/null 2>&1 && return 0
	log "installing Xcode Command Line Tools (finish the dialog that opens)"
	xcode-select --install >/dev/null 2>&1 || true
	until xcode-select -p >/dev/null 2>&1; do sleep 5; done
}

contains() { local n=$1; shift; local x; for x in "$@"; do [[ $x == "$n" ]] && return 0; done; return 1; }

sync_repo() {
	ensure_git
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
		git check-ignore -q -- "$dir/$rel" && continue
		# absolute target: a relative one would resolve against the link's own
		# directory, not $HOME, once we're more than one level deep
		link "$DOTFILES/$dir/$rel" "$HOME/$dir/$rel"
	done < <(cd "$DOTFILES/$dir" && find . -type f -print0)
}

[[ -n ${DOTFILES_REEXEC:-} ]] || sync_repo
cd "$DOTFILES"

for f in .??* *; do
	[[ -e $f ]] || continue
	contains "$f" "${NO_LINK[@]}" && continue
	# local-only state (.claude/, .DS_Store, ...) must never land in $HOME
	git check-ignore -q -- "$f" && continue
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
if [[ ! -x $HOME/.fzf/bin/fzf ]]; then
	"$HOME/.fzf/install" --key-bindings --completion --no-update-rc </dev/null >/dev/null
fi

# -------------------------------------------------------------------- macos ---

if [[ "$OSTYPE" == "darwin"* ]]; then
	# the top of this block is personal modifications,
	# after dock settings, most are plucked straight from mathias bynens setup
	# https://github.com/mathiasbynens/dotfiles/blob/main/.macos

	# one setting I always adjust that is not captured here and needs to be
	# configured by hand:
	#  - night shift always on

	# Apple silicon and Intel keep homebrew in different places
	if [[ "$(uname -m)" == "arm64" ]]; then BREW_PREFIX=/opt/homebrew; else BREW_PREFIX=/usr/local; fi
	ME=$(id -un)

	if [[ ! -x $BREW_PREFIX/bin/brew ]]; then
		log "installing homebrew"
		# NONINTERACTIVE homebrew needs sudo to already be authenticated
		need_sudo "installing homebrew"
		NONINTERACTIVE=1 /bin/bash -c \
			"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/null
	fi
	# needed on a fresh install: brew isn't on PATH yet in this shell
	eval "$("$BREW_PREFIX/bin/brew" shellenv)"

	SHELL_PATH="$BREW_PREFIX/bin/bash"
	if [[ ! -x $SHELL_PATH ]]; then
		log "installing bash"
		brew install bash </dev/null
	fi
	if ! grep -qxF "$SHELL_PATH" /etc/shells; then
		need_sudo "adding $SHELL_PATH to /etc/shells"
		echo "$SHELL_PATH" | sudo tee -a /etc/shells >/dev/null
	fi
	if [[ "$(dscl . -read "/Users/$ME" UserShell | awk '{print $2}')" != "$SHELL_PATH" ]]; then
		need_sudo "setting login shell to $SHELL_PATH"
		sudo chsh -s "$SHELL_PATH" "$ME"
	fi

	DOCK_DOMAINS=(com.apple.dock com.apple.WindowManager)
	FINDER_DOMAINS=(com.apple.finder NSGlobalDomain com.apple.screencapture com.apple.Siri com.apple.HIToolbox)
	DOCK_BEFORE=$(prefs_state "${DOCK_DOMAINS[@]}")
	FINDER_BEFORE=$(prefs_state "${FINDER_DOMAINS[@]}")

	# Set a pretty fast keyboard repeat rate
	set_default NSGlobalDomain KeyRepeat -int 2
	set_default NSGlobalDomain InitialKeyRepeat -int 15

	# ctrl + cmd + click drag window similar to x11
	set_default -g NSWindowShouldDragOnGesture -bool true

	# f1-f12 behave as standard function keys (hold fn for brightness, volume, ...)
	set_default NSGlobalDomain com.apple.keyboard.fnState -bool true

	# tab moves keyboard focus between all controls, not just text boxes and lists
	set_default NSGlobalDomain AppleKeyboardUIMode -int 2

	# caps lock -> control. hidutil mappings are lost at logout, so a LaunchAgent
	# reapplies the mapping at every login. Written here rather than linked from
	# the repo because launchd is picky about symlinked agents.
	CAPS_LABEL="local.dotfiles.capslock-control"
	CAPS_PLIST="$HOME/Library/LaunchAgents/$CAPS_LABEL.plist"
	CAPS_MAP='{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}'
	CAPS_WANT=$(cat <<-PLIST
		<?xml version="1.0" encoding="UTF-8"?>
		<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
		<plist version="1.0">
		<dict>
			<key>Label</key>
			<string>$CAPS_LABEL</string>
			<key>ProgramArguments</key>
			<array>
				<string>/usr/bin/hidutil</string>
				<string>property</string>
				<string>--set</string>
				<string>$CAPS_MAP</string>
			</array>
			<key>RunAtLoad</key>
			<true/>
		</dict>
		</plist>
	PLIST
	)
	if [[ ! -f $CAPS_PLIST || "$(cat "$CAPS_PLIST")" != "$CAPS_WANT" ]]; then
		log "installing caps lock -> control login agent"
		mkdir -p "$(dirname "$CAPS_PLIST")"
		printf '%s\n' "$CAPS_WANT" >"$CAPS_PLIST"
		launchctl bootout "gui/$(id -u)/$CAPS_LABEL" 2>/dev/null || true
		launchctl bootstrap "gui/$(id -u)" "$CAPS_PLIST" 2>/dev/null \
			|| warn "could not load $CAPS_LABEL, it will start at next login"
	fi

	# Make list view the Finder default. Folders that were already opened keep
	# their own view in a .DS_Store, so the first time through clear those out.
	# Only on the first run: after that it would throw away per-folder choices
	# made since. ~/Library and friends are TCC-protected, so prune them.
	if [[ "$(get_default com.apple.finder FXPreferredViewStyle)" != "Nlsv" ]]; then
		log "clearing .DS_Store files under $HOME"
		find "$HOME" \
			\( -path "$HOME/Library" \
			-o -path "$HOME/.Trash" \
			-o -path "$HOME/.dotfiles/.git" \
			-o -name "node_modules" \
			-o -name "*.photoslibrary" \
			-o -name "*.sparsebundle" \
			\) -prune \
			-o -name ".DS_Store" -type f -print0 2>/dev/null \
			| xargs -0 rm -f || true
		set_default com.apple.finder FXPreferredViewStyle -string "Nlsv"
	fi

	# Dock position, hiding, size
	set_default com.apple.dock orientation -string "left"
	set_default com.apple.dock autohide -bool true
	set_default com.apple.dock tilesize -int 36

	# always show scrollbar
	set_default NSGlobalDomain AppleShowScrollBars -string "Always"

	# scroll direction
	set_default NSGlobalDomain com.apple.swipescrolldirection -bool false

	# Disable press-and-hold for keys in favor of key repeat
	set_default NSGlobalDomain ApplePressAndHoldEnabled -bool false

	# Require password immediately after sleep or screen saver begins.
	# The old com.apple.screensaver askForPassword* keys have been ignored since
	# 10.13; the real setting lives behind sysadminctl and needs the account
	# password, so check it and say how to fix it rather than prompting here.
	if ! sysadminctl -screenLock status 2>&1 | grep -q "immediate"; then
		warn "screen lock is not immediate. to fix: sysadminctl -screenLock immediate -password -"
	fi

	# Finder: allow quitting via ⌘ + Q; doing so will also hide desktop icons
	set_default com.apple.finder QuitMenuItem -bool true

	# Finder: disable window animations and Get Info animations
	set_default com.apple.finder DisableAllAnimations -bool true

	# Set Home as the default location for new Finder windows
	set_default com.apple.finder NewWindowTarget -string "PfHm"
	set_default com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

	# Nothing on the desktop: no drive, server or removable media icons, and no
	# file icons either (files in ~/Desktop are still there, just not drawn)
	set_default com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
	set_default com.apple.finder ShowHardDrivesOnDesktop -bool false
	set_default com.apple.finder ShowMountedServersOnDesktop -bool false
	set_default com.apple.finder ShowRemovableMediaOnDesktop -bool false
	set_default com.apple.finder CreateDesktop -bool false

	# No recent tags in the Finder sidebar
	set_default com.apple.finder ShowRecentTags -bool false

	# Don't litter network and USB volumes with .DS_Store files
	set_default com.apple.desktopservices DSDontWriteNetworkStores -bool true
	set_default com.apple.desktopservices DSDontWriteUSBStores -bool true

	# Finder: show all filename extensions
	set_default NSGlobalDomain AppleShowAllExtensions -bool true

	# Finder: show status bar
	set_default com.apple.finder ShowStatusBar -bool true

	# Finder: show path bar
	set_default com.apple.finder ShowPathbar -bool true

	# Display full POSIX path as Finder window title
	set_default com.apple.finder _FXShowPosixPathInTitle -bool true

	# Keep folders on top when sorting by name
	set_default com.apple.finder _FXSortFoldersFirst -bool true

	# When performing a search, search the current folder by default
	set_default com.apple.finder FXDefaultSearchScope -string "SCcf"

	# Disable the warning when changing a file extension
	set_default com.apple.finder FXEnableExtensionChangeWarning -bool false

	# Enable spring loading for directories
	set_default NSGlobalDomain com.apple.springing.enabled -bool true

	# Remove the spring loading delay for directories
	set_default NSGlobalDomain com.apple.springing.delay -float 0

	# Change minimize/maximize window effect
	set_default com.apple.dock mineffect -string "scale"

	# Minimize windows into their application’s icon
	set_default com.apple.dock minimize-to-application -bool true

	# Show indicator lights for open applications in the Dock
	set_default com.apple.dock show-process-indicators -bool true

	# Wipe all (default) app icons from the Dock, once: static-only below hides
	# pinned apps anyway, and this way a re-run never clears a Dock you rebuilt.
	if [[ "$(get_default com.apple.dock static-only)" != "1" ]]; then
		set_default com.apple.dock persistent-apps -array
	fi

	# Show only open applications in the Dock
	set_default com.apple.dock static-only -bool true

	# Don’t animate opening applications from the Dock
	set_default com.apple.dock launchanim -bool false

	# Don’t show recent applications in Dock
	set_default com.apple.dock show-recents -bool false

	# Clicking the wallpaper no longer shoves every window aside to show the
	# desktop (Desktop & Dock > "Click wallpaper to reveal desktop" > Only in
	# Stage Manager)
	set_default com.apple.WindowManager EnableStandardClickToShowDesktop -bool false

	# No widgets on the desktop, with or without Stage Manager
	set_default com.apple.WindowManager StandardHideWidgets -bool true
	set_default com.apple.WindowManager StageManagerHideWidgets -bool true

	# Stage Manager off, and tiled windows sit flush with no gaps between them
	set_default com.apple.WindowManager GloballyEnabled -bool false
	set_default com.apple.WindowManager EnableTiledWindowMargins -bool false

	# No hot corners (1 = no action). Bottom right is Quick Note out of the box.
	for corner in tl tr bl br; do
		set_default com.apple.dock "wvous-$corner-corner" -int 1
		set_default com.apple.dock "wvous-$corner-modifier" -int 0
	done

	# Dock appears the moment the pointer hits the edge, and slides in quickly
	set_default com.apple.dock autohide-delay -float 0
	set_default com.apple.dock autohide-time-modifier -float 0.2

	# Don't reorder Spaces by most recent use
	set_default com.apple.dock mru-spaces -bool false

	# Type what I type: no autocorrect, auto-capitalisation, smart quotes,
	# smart dashes, or double-space-to-period
	set_default NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
	set_default NSGlobalDomain WebAutomaticSpellingCorrectionEnabled -bool false
	set_default NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
	set_default NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
	set_default NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
	set_default NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

	# Save and print dialogs open expanded, and new documents save to disk
	# rather than iCloud
	set_default NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
	set_default NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
	set_default NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
	set_default NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
	set_default NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

	# Screenshots: own folder, no floating thumbnail, no window shadow
	mkdir -p "$HOME/Screenshots"
	set_default com.apple.screencapture location -string "$HOME/Screenshots"
	set_default com.apple.screencapture show-thumbnail -bool false
	set_default com.apple.screencapture disable-shadow -bool true

	# Menu bar: always visible (auto-hiding leaves a bare notch on laptops), but
	# without the Spotlight and Siri icons
	set_default NSGlobalDomain _HIHideMenuBar -bool false
	set_default -currentHost com.apple.Spotlight MenuItemHidden -int 1
	set_default com.apple.Siri StatusMenuVisible -bool false

	# ---- classic look: undo what Tahoe's Liquid Glass redesign changed ----

	# Solid menu bar background instead of a transparent one
	set_default NSGlobalDomain SLSMenuBarUseBlurredAppearance -bool true

	# No glyph next to every menu item
	set_default NSGlobalDomain NSMenuEnableActionImages -bool false

	# Windows don't pick up a tint from the wallpaper behind them
	set_default NSGlobalDomain AppleReduceDesktopTinting -bool true

	# Classic blue accent and highlight colour
	set_default NSGlobalDomain AppleAccentColor -int 4
	set_default NSGlobalDomain AppleAquaColorVariant -int 1
	set_default NSGlobalDomain AppleHighlightColor -string "0.698039 0.843137 1.000000 Blue"

	# Windows stay where they're dropped: no tiling when dragged to a screen
	# edge or the menu bar, and no tiling preview while holding option
	set_default com.apple.WindowManager EnableTilingByEdgeDrag -bool false
	set_default com.apple.WindowManager EnableTopTilingByEdgeDrag -bool false
	set_default com.apple.WindowManager EnableTilingOptionAccelerator -bool false

	# Windows open, close and resize without animation
	set_default NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
	set_default NSGlobalDomain NSWindowResizeTime -float 0.001

	# Title bar folder icon appears immediately instead of after a hover delay
	set_default NSGlobalDomain NSToolbarTitleViewRolloverDelay -float 0

	# Quitting an app closes its windows; they don't come back on relaunch
	set_default NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false

	# ---- less assistant, less noise ----

	# Siri off
	set_default com.apple.assistant.support "Assistant Enabled" -bool false

	# fn/globe key does nothing on its own (no emoji picker, no dictation)
	set_default com.apple.HIToolbox AppleFnUsageType -int 0

	# No interface sound effects, no pop when changing volume
	set_default NSGlobalDomain com.apple.sound.uiaudio.enabled -int 0
	set_default NSGlobalDomain com.apple.sound.beep.feedback -int 0

	# No startup chime. Stored in NVRAM, so it needs sudo; skipped with a
	# warning when there's no way to ask for a password.
	if [[ "$(nvram StartupMute 2>/dev/null | awk '{print $2}')" != "%01" ]]; then
		if try_sudo "muting the startup chime"; then
			sudo nvram StartupMute=%01
		else
			warn "startup chime left on (no sudo). to fix: sudo nvram StartupMute=%01"
		fi
	fi

	# Accessibility display options: less motion and transparency, borders on
	# toolbar buttons, always-visible title bar icons, higher contrast. This
	# domain is TCC-protected, so like Mail it only works once the terminal has
	# Full Disk Access.
	if defaults write com.apple.universalaccess reduceMotion -bool true 2>/dev/null; then
		set_default com.apple.universalaccess reduceTransparency -bool true
		set_default com.apple.universalaccess showToolbarButtonShapes -bool true
		set_default com.apple.universalaccess showWindowTitlebarIcons -bool true
		set_default com.apple.universalaccess increaseContrast -bool true
	else
		warn "skipping accessibility display settings: this terminal lacks Full Disk Access"
	fi

	# Mail is sandboxed: its preferences live in ~/Library/Containers, which
	# macOS only lets a terminal touch once it has Full Disk Access. Without it
	# every write below fails, so skip the block instead of aborting the run.
	MAIL_PREFS="$HOME/Library/Containers/com.apple.mail/Data/Library/Preferences"
	if [[ ! -d "$HOME/Library/Containers/com.apple.mail" ]] || ls "$MAIL_PREFS" >/dev/null 2>&1; then
		# Copy email addresses as `foo@example.com` instead of `Foo Bar <foo@example.com>` in Mail.app
		set_default com.apple.mail AddressesIncludeNameOnPasteboard -bool false

		# Add the keyboard shortcut ⌘ + Enter to send an email in Mail.app
		set_default com.apple.mail NSUserKeyEquivalents -dict-add "Send" "@\U21a9"

		# Disable automatic spell checking
		set_default com.apple.mail SpellCheckingBehavior -string "NoSpellCheckingEnabled"
	else
		warn "skipping Mail settings: this terminal lacks Full Disk Access"
		warn "  grant it in System Settings > Privacy & Security > Full Disk Access, then re-run"
	fi

	# defaults writes don't take effect until the app restarts, but only bounce
	# the ones whose settings actually changed this run
	if [[ "$(prefs_state "${DOCK_DOMAINS[@]}")" != "$DOCK_BEFORE" ]]; then
		log "restarting Dock"
		killall Dock WindowManager >/dev/null 2>&1 || true
	fi
	if [[ "$(prefs_state "${FINDER_DOMAINS[@]}")" != "$FINDER_BEFORE" ]]; then
		log "restarting Finder"
		killall Finder SystemUIServer >/dev/null 2>&1 || true
	fi
fi

if (( FAILED > 0 )); then
	warn "$FAILED setting(s) could not be written, see warnings above"
fi
log "done. open a new shell to pick everything up."

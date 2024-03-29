#!/bin/bash
rm -rf ~/.bash_profile \
	~/.bashrc \
	~/.zsh* \
	~/.profile

if [ -d ~/.dotfiles ]; then
	cd ~/.dotfiles
	git pull --ff-only
else
	git clone https://github.com/samdixon/dotfiles ~/.dotfiles
fi

cd ~/.dotfiles
for f in .???*; do
    if [[ $f != ".git" ]]; then
        rm -f ~/$f
        (cd ~/; ln -s .dotfiles/$f $f)
    fi
done

if [ ! -d ~/.fzf ]; then
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
	~/.fzf/install
fi

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
    # if we don't have homebrew, go ahead and install it
    # todo: if no brew, install brew
    if [[ ! -f "/opt/homebrew/bin/brew" ]]; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # add brew bash to available shells
    # if no brew bash installed, install it first
    SHELL_PATH="/opt/homebrew/bin/bash"
    if [[ -f "$SHELL_PATH" ]]; then
        echo "$SHELL_PATH" | sudo tee -a /etc/shells
        chsh -s $SHELL_PATH
    else
        brew install bash;
        echo "$SHELL_PATH" | sudo tee -a /etc/shells;
        chsh -s $SHELL_PATH;
    fi


    # Set a pretty fast keyboard repeat rate
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15

    # cmd + click drag window similar to x11
    defaults write -g NSWindowShouldDragOnGesture -bool true

    # remove all .DS_store files which hold information about finder window display
    # only removing for user dir
    find $HOME -name ".DS_Store" -depth -exec rm {} \;

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
fi

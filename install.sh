#!/bin/sh
set -e

rm -rf ~/.bash* \
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
	rm -f ~/$f
	(cd ~/; ln -s .dotfiles/$f $f)
done

if [ ! -d ~/.vim/bundle/Vundle.vim ]; then
	git clone https://github.com/VundleVim/Vundle.vim.git \
		~/.vim/bundle/Vundle.vim
fi

if [ ! -d ~/.fzf ]; then
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
	~/.fzf/install
fi


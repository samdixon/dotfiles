# Jump to a project directory
# ---------------------------
# Thin shell wrapper around ~/bin/project-dir, which does the fzf picking and
# prints an absolute path. The cd has to happen in this shell, so it lives here
# as a function rather than as another script in ~/bin.

# Projects live under ~/me/projects. Export PROJECT_DIR_ROOT before this file is
# sourced to point somewhere else.
export PROJECT_DIR_ROOT="${PROJECT_DIR_ROOT:-$HOME/me/projects}"

# Key that opens the picker from the prompt. NOT Ctrl-D: readline turns Ctrl-D
# on an empty line into EOF and exits the shell before it ever looks at the
# keymap, so it can't be rebound (macro, `bind -x`, .inputrc and `stty eof
# undef` were all tried).
PROJECT_JUMP_KEY="${PROJECT_JUMP_KEY:-\C-g}"

__project_dir_bin() {
	command -v project-dir 2>/dev/null && return 0
	[ -x "$HOME/bin/project-dir" ] && { printf '%s\n' "$HOME/bin/project-dir"; return 0; }
	printf 'project-dir: not found on PATH or in ~/bin\n' >&2
	return 1
}

# j [project-dir options] [query] -- pick a project and cd into it.
# With a query that matches exactly one project, project-dir's --select-1 skips
# the picker entirely, so `j dotfiles` jumps straight there.
j() {
	local bin dest
	bin="$(__project_dir_bin)" || return 1
	dest="$("$bin" "$@")" || return $?
	[ -n "$dest" ] || return 1
	cd "$dest" || return $?
	printf '%s\n' "$PWD"
}

# Same pick, but open a new tmux window there instead of moving this shell.
jt() {
	local bin dest
	bin="$(__project_dir_bin)" || return 1
	[ -n "${TMUX:-}" ] || { printf 'jt: not inside tmux\n' >&2; return 1; }
	dest="$("$bin" "$@")" || return $?
	[ -n "$dest" ] || return 1
	tmux new-window -c "$dest" -n "$(basename "$dest")"
}

# Complete on project names so `j dot<tab>` fills in a real candidate.
__j_complete() {
	local bin cur root
	bin="$(command -v project-dir 2>/dev/null || printf '%s' "$HOME/bin/project-dir")"
	[ -x "$bin" ] || return 0
	cur="${COMP_WORDS[COMP_CWORD]}"
	root="${PROJECT_DIR_ROOT:-$HOME/me/projects}"
	local IFS=$'\n'
	COMPREPLY=($(compgen -W "$("$bin" --list 2>/dev/null | sed "s|^$root/||")" -- "$cur"))
}
complete -F __j_complete j jt

# Bind the key to a macro rather than `bind -x`: the trailing C-m ends the line,
# so the next prompt is redrawn with the new $PWD (a `bind -x` cd leaves the
# already-expanded prompt showing the old \w). C-a C-k parks anything already
# typed in the kill ring, so C-y pastes it back after the jump, and the leading
# space keeps `j` out of history under HISTCONTROL=ignoreboth.
if [[ $- == *i* ]]; then
	__project_jump_bind() {
		local keymap
		for keymap in emacs-standard vi-insert; do
			bind -m "$keymap" "\"${PROJECT_JUMP_KEY}\": \"\\C-a\\C-k j\\C-m\"" 2>/dev/null
		done
	}
	__project_jump_bind
fi

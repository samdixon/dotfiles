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

# Setup cdg function
# ------------------
unalias cdg 2> /dev/null
cdg() {
   local dest_dir=$(cdscuts_glob_echo | fzf )
   if [[ $dest_dir != '' ]]; then
      cd "$dest_dir"
   fi
}
export -f cdg > /dev/null

alias runmake='$(cat Makefile | grep : | cut -d ":" -f1 | awk '\''{print "make " $0}'\'' - | fzf)'

#!/bin/bash

notes_path="/home/girts/Documents/notes"

temp_file=$(mktemp)

cd $notes_path || exit 1

find $notes_path -type d -name ".venv" -prune -o -type f -print | fzf --preview 'batcat --color=always {}' >$temp_file
file=$(cat $temp_file)
rm $temp_file

if [[ -f "$file" ]]; then
  nvim "$file"
else
  echo "File does not exist"
  cd -
fi

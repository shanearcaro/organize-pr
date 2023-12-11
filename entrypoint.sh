#!/bin/sh

# Mark as safe directory
git config --global --add safe.directory $PWD

# Read in path and languages to traverse
paths=$1
languages=$2
printenv

# Define aliases
head=$GITHUB_HEAD_REF
base=$GITHUB_BASE_REF
git_event=$GITHUB_EVENT_NAME

# Add a label to a pull request or issue
add_label() {
  if [ "$git_event" = "pull_request" ]; then
    gh pr edit --add-label "$1"
  else
    gh issue edit --add-label "$1"
  fi
}

# Search for a label
search_label() {
  label=$(echo $1 | xargs)
  search=$(gh label list -S $label)
  echo $search
}

create_label() {
  # Remove trailing whitespace
  label=$(echo $1 | xargs)
  gh label create "$label" -d "Label automatically created by shanearcaro/organize-pr"
}

# Check if a label exists, if not create it
check_label() {
  label=$(echo $1 | xargs)
  search=$(search_label "$label")
  if [ -z "$search" ]; then
    echo "Creating label: $label"
    create_label "$label"
  else
    echo "Label exists: $search"
  fi
}

# Get changed files from a pull request or issue
get_changed_files() {
  changed_files=""
  if [ $git_event = "pull_request" ]; then
    changed_files=$(git diff --name-only origin/"$head" origin/"$base")
  else
    changed_files=$(git diff --name-only origin/"$head")
  fi
  echo $changed_files
}

# Get unique file extensions from changed files
get_changed_file_ext() {
  changed_files=$(get_changed_files)
  extensions=""
  for file in $changed_files; do
    # Extract file extensions
    file_ext="${file##*.}"
    extensions="$extensions $file_ext"
  done
  
  # Remove duplicate extensions, need to convert spaces to new lines then back again
  extensions=$(echo $extensions | tr ' ' '\n' | sort -u | tr '\n' ' ')
  echo $extensions
}

# Add language labels to an event
add_language_labels() {
  extensions=$(get_changed_file_ext)
  echo "Extensions: $extensions"

  for ext in $extensions; do
    # Check if file extension is in languages
    match=$(echo "$languages" | grep "$ext" | awk '{print $2}' | xargs)
    if [ -n "$match" ]; then
      # Get label
      echo "Match: $match"
      check_label "$match"
      add_label $match
    fi
  done
}

# Need to checkout branch before using git commands
gh pr checkout origin/"$head"

echo "Running comparison on "$head" and "$base""
add_language_labels


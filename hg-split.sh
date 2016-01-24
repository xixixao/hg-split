#!/bin/bash

if [ "$1" = "--help" ] || [ "$1" = "help" ]; then
  echo "hg-split [OPTIONS] [HG_COMMIT_OPTIONS] -- [FILE]..."
  echo ""
  echo "split current commit into two"
  echo ""
  echo "    Moves the files passed in to a new, sibling commit."
  echo ""
  echo "    For example:"
  echo ""
  echo "        hg-split --shelve -n -b other -m \"Others\" -- foo.txt bar.txt"
  echo ""
  echo "    commits the changes made to foo.txt and bar.txt in this commit as a"
  echo "    new commit which has the same parent. Also sets bookmark 'other'"
  echo "    to this new commit. If there are uncommited changes, shelves them"
  echo "    and unshelves them at the original commit at the end. If there are"
  echo "    no uncommited changes, updates to the 'other' bookmark. The new"
  echo "    commit has a message: \"Others\"."
  echo ""
  echo "OPTIONS can be any of:"
  echo "    --help            shows this help listing"
  echo " -b --bookmark NAME   put a new bookmark on the newly created commit "
  echo " -n --up-new          update to the newly created commit"
  echo "    --shelve          shelve pending changes automatically"
  exit
fi

# Parse arguments
commit_args=()
picked_files=()
after_separator=false
while [[ $# > 0 ]]; do
  key="$1"

  if [[ $after_separator = true ]]; then
    picked_files+=("$1")
  else
    case $key in
      -b|--bookmark)
      bookmark="$2"
      shift # past value
      ;;
      -n|--up-new)
      up_new=true
      ;;
      --shelve)
      do_shelve=true
      ;;
      --dirty)
      # for efficiency, allow the command line to specify whether the current
      # commit is dirty
      dirty="$2"
      shift # past value
      ;;
      --)
      after_separator=true
      ;;
      *)
      commit_args+=("$1")
      ;;
    esac
  fi
  shift # past argument
done

# Get path to our node module
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# 0 if dirty
if [[ ! -z $dirty ]]; then
  is_dirty=$dirty
else
  is_dirty=$([[ ! -z `hg status | grep -v '^?'` ]] ; echo $?)
fi &&

# 0. Shelve current changes if any
if [[ $is_dirty -eq 0 ]]; then
  if [[ $do_shelve != true ]]; then
    echo "abort: uncommitted changes"
    exit
  else
    hg shelve; #ignore result
  fi
fi &&

# Remember current commit/bookmark from summary
original=`$DIR/hg-current.sh` &&

# 1. Go to parent
hg up -r .^ &&

# 2. Revert picked files to state in original commit
hg revert -r "$original" ${picked_files[@]} &&

# Bookmark before commiting
if [[ ! -z "$bookmark" ]]; then
  hg book "$bookmark" &&
  destination="$bookmark" || true; # ignore fail
fi &&

# 3. Commit them into a new commit
hg commit "${commit_args[@]}" &&

if [[ -z "$destination" ]]; then
  destination=`$DIR/hg-current.sh`
fi &&

# 4. Go to original commit, revert files to parent
hg up "$original" &&
hg revert ${picked_files[@]} -r .^ &&

# 5. Amend the original commit
hg amend --rebase &&

# 6. Unstage changes
if [[ $is_dirty -eq 0 ]] && [[ $do_shelve = true ]]; then
  hg unshelve
fi &&

# If not dirty and --new, go to new bookmark/commit
if [[ $is_dirty -ne 0 ]] && [[ $up_new = true ]]; then
  hg up "$destination"
fi

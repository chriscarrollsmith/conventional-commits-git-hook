#!/bin/sh

#config_file_name="conventional-commits.json"

# checks that jq is usable
#function check_jq_exists_and_executable {
#if ! [ -x "$(command -v jq)" ]; then
#  echo -e "\`commit-msg\` hook failed. Please install jq."
#  exit 1
#fi
#}

# set values from config file to variables
set_config_values() {
#  local_config="$PWD/$config_file_name"
#
#  if [ -f "$local_config" ]; then
#    CONFIG=$local_config
#    types="build docs feat fix perf refactor style test chore"
#  else
    types="build docs feat fix perf refactor style test chore"
#  fi
}

# build the regex pattern based on the config file
build_regex() {
  set_config_values

  regexp="^[.0-9]+$|"

  regexp="${regexp}^([Rr]evert|[Mm]erge):? .*$|^("

  for type in $types
  do
    regexp="${regexp}$type|"
  done

  regexp="${regexp%|})(\(.+\))?!?: "
}

# get the first line of the commit message
INPUT_FILE=$1
commit_message=`head -n1 $INPUT_FILE`

# Print out a standard error message which explains
# how the commit message should be structured
print_error() {
  regular_expression=$2
  printf "\n\033[31m[Invalid Commit Message]\033[0m\n"
  printf "%s\n" "------------------------"
  printf "Valid types: \033[36m%s\033[0m\n" "$types"
  printf "\033[37mActual commit message: \033[33m\"%s\"\033[0m\n" "$commit_message"
  printf "\033[37mExample valid commit message: \033[36m\"fix(subject): message\"\033[0m\n"
  printf "\033[37mRegex: \033[33m\"%s\"\033[0m\n" "$regexp"
}

build_regex

if ! echo "$commit_message" | grep -qE "$regexp"; then
  # commit message is invalid according to config - block commit
  print_error
  exit 1
fi

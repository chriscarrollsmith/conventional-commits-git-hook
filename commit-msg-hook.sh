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

  # Allow version tags (e.g., 1.0.0) or merge/revert commits
  regexp="^[.0-9]+$|"
  regexp="${regexp}^(revert|merge):? .*$|"

  # Build type matching (case insensitivity handled by grep -i)
  regexp="${regexp}^("

  for type in $types
  do
    regexp="${regexp}$type|"
  done

  # Remove trailing pipe and add scope, breaking change, and description pattern
  # Scope: optional, must contain alphanumeric, hyphens, underscores, or spaces
  # Breaking change: optional ! before colon
  # Description: required, must have at least one non-whitespace character
  regexp="${regexp%|})(\([a-zA-Z0-9 _-]+\))?!?: .*[^[:space:]].*$"
}

# Validate full commit message structure
validate_full_message() {
  local file=$1
  local line_num=0
  local in_body=false
  local has_body=false
  local blank_after_subject=false
  local error_msg=""

  while IFS= read -r line || [ -n "$line" ]; do
    line_num=$((line_num + 1))

    # Skip the first line (already validated)
    if [ $line_num -eq 1 ]; then
      continue
    fi

    # Line 2: if present, must be blank
    if [ $line_num -eq 2 ]; then
      if [ -n "$line" ] && ! echo "$line" | grep -qE '^\s*$'; then
        error_msg="Line 2 must be blank if body or footer is present"
        echo "$error_msg"
        return 1
      fi
      blank_after_subject=true
      continue
    fi

    # For lines 3+, check if it's blank
    if [ -z "$line" ] || echo "$line" | grep -qE '^\s*$'; then
      in_body=false  # Blank line might separate body from footer
      continue
    fi

    # Check for footer pattern (token: value or token #value)
    if echo "$line" | grep -qE '^[A-Za-z][-A-Za-z]*( [-A-Za-z]+)*[[:space:]]*(:|#)'; then
      # Validate BREAKING CHANGE footer is uppercase (must check all case variations)
      if echo "$line" | grep -qiE '^breaking[[:space:]]*change[[:space:]]*:' && ! echo "$line" | grep -qE '^BREAKING CHANGE[[:space:]]*:'; then
        error_msg="BREAKING CHANGE footer must be uppercase (line $line_num: \"$line\")"
        echo "$error_msg"
        return 1
      fi
      continue
    fi

    # Regular body content
    has_body=true
    in_body=true
  done < "$file"

  return 0
}

# get the first line of the commit message
INPUT_FILE=$1
commit_message=`head -n1 $INPUT_FILE`

# Print out a standard error message which explains
# how the commit message should be structured
print_error() {
  local custom_msg=$1
  printf "\n\033[31m[Invalid Commit Message]\033[0m\n"
  printf "%s\n" "------------------------"
  if [ -n "$custom_msg" ]; then
    printf "\033[31m%s\033[0m\n\n" "$custom_msg"
  fi
  printf "Valid types (case-insensitive): \033[36m%s\033[0m\n" "$types"
  printf "\033[37mActual commit message: \033[33m\"%s\"\033[0m\n" "$commit_message"
  printf "\033[37mFormat: \033[36mtype(scope): description\033[0m\n"
  printf "\033[37mExample: \033[36mfeat(auth): add OAuth2 login\033[0m\n"
  printf "\033[37mWith breaking change: \033[36mfeat(api)!: remove deprecated endpoint\033[0m\n"
  printf "\033[37mRegex: \033[33m%s\033[0m\n" "$regexp"
  printf "\nSee https://www.conventionalcommits.org for full specification\n"
}

build_regex

# Validate the first line (subject) - use case-insensitive matching per spec
if ! echo "$commit_message" | grep -iqE "$regexp"; then
  # commit message is invalid according to config - block commit
  print_error
  exit 1
fi

# Validate full message structure (body/footer formatting)
if ! validation_error=$(validate_full_message "$INPUT_FILE"); then
  print_error "$validation_error"
  exit 1
fi

unalias gbc 2>/dev/null

gbc() {
  local branch_name

  branch_name="$(git branch --show-current 2>/dev/null)"

  if [[ -z "$branch_name" ]]; then
    echo "\033[31mError:\033[0m not on a branch or not inside a git repository."
    return 1
  fi

  printf "%s" "$branch_name" | pbcopy
  echo "Copied current branch: $branch_name"
}
# Alias gsc : Forcefully switch or create a Git branch
unalias gsc 2>/dev/null
gsc() {
  # Gérer les options courtes et longues
  local help_requested=false
  local error_found=false
  local force_switch=false
  local args=()

  while getopts ":hf" option; do
    case $option in
      h)
        help_requested=true
        ;;
      f)
        force_switch=true
        ;;
      \?)
        help_requested=true
        ;;
      \*)
        echo $option
        help_requested=true
        error_found=true
        ;;
    esac
  done

  shift $((OPTIND - 1))
  for arg in "$@"; do
    case "$arg" in
      --help)
        help_requested=true
        ;;
      --force)
        force_switch=true
        ;;
      *)
        args+=("$arg")
        ;;
    esac
  done

  # Vérification : s'il y a exactement un argument restant
  if ! $help_requested && ! $error_found && [[ ${#args[@]} -ne 1 ]]; then
    echo "\x1b[31m\x1b[1mError:\x1b[0m \x1b[31mExactly \x1b[1mone\x1b[0m \x1b[31mbranch name is required.\x1b[0m"
    error_found=true
  fi

  # Extraire le nom de la branche
  local branch_name="${args}"

  # Vérification de la validité du nom de branche
  if ! $help_requested && ! $error_found && ! git check-ref-format --branch "$branch_name" &>/dev/null; then
    echo "\x1b[31mError: '$branch_name' is not a valid branch name.\x1b[0m"
    error_found=true
  fi

  # Afficher l'aide si demandée ou erreur détectée
  if $help_requested || $error_found; then
    if $error_found; then
      echo "\x1b[31m\x1b[2mError: An error occurred.\x1b[0m"
      echo ""
    fi

    echo "\x1b[1mUsage:\x1b[0m gsc [-f|--force] <branch-name>"
    echo "\x1b[2mForcefully switch to or create a branch."
    echo "\x1b[3m-> git switch shortcut\x1b[0m"
    echo ""
    echo "\x1b[1mOptions:\x1b[0m"
    echo "  -f, --force   \x1b[2mPass -f to the git switch command (force switch)\x1b[0m"
    echo "  -h, --help    \x1b[2mShow this help\x1b[0m"
    if $error_found; then
      return 1
    fi

    return 0
  fi

  # Construire la commande git switch
  if $force_switch; then
    git switch -c "$branch_name" -f
  else
    git switch -c "$branch_name"
  fi
}

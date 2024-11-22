# Alias gg : Afficher le graphe Git
unalias gg 2>/dev/null
gg() {
  # Gérer les options courtes et longues
  local help_requested=false
  local error_found=false
  local args=()

  while getopts ":h" option; do
    case $option in
      h)
        help_requested=true
        ;;
      \?)
        help_requested=true
        error_found=true
        ;;
      \*)
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
      *)
        args+=("$arg")
        ;;
    esac
  done

  # Vérification : si l'argument est un entier positif
  local n=${args:-25}  # Par défaut, profondeur 25
  if [[ ${#args[@]} -gt 1 ]]; then
    echo "\x1b[31mOnly one or no argument accepted\x1b[0m"
    error_found=true
  fi
  if [[ ${#args[@]} == 1 ]] && ! [[ "$n" =~ ^[0-9]+$ ]]; then
    echo "\x1b[31mArgument 'depth' should be an integer\x1b[0m"
    error_found=true
  fi

  # Afficher l'aide si demandée
  if $help_requested || $error_found; then
    if $error_found; then
        echo "\x1b[31m\x1b[2mError: an error occured\x1b[0m"
        echo ""
    fi

    echo "\x1b[1mUsage:\x1b[0m \x1b[2mgg <depth(25)>\x1b[0m"
    echo "\x1b[2mShow formatted git graph logs.\x1b[0m"
    if $error_found; then
        return 1
    fi    

    return 0
  fi

  git --no-pager log --graph --oneline --decorate --all -n "$n" --pretty=format:'%C(auto)%h %d %s %C(green)(%ar) %C(yellow)[%ai] %C(bold blue)<%an>'
}

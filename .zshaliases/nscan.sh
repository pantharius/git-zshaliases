# Alias nscan : Scanner les processus Node.js
unalias nscan 2>/dev/null
nscan() {
  local help_requested=false
  local error_found=false

  # Gestion des options
  while getopts ":h" opt; do
    case "$opt" in
    h) help_requested=true ;;
    \?)
      help_requested=true
      error_found=true
      ;;
    esac
  done

  shift $((OPTIND - 1))
  for arg in "$@"; do
    case "$arg" in
    --help) help_requested=true ;;
    *)
      echo -e "\x1b[31mUnknown argument: $arg\x1b[0m"
      help_requested=true
      error_found=true
      ;;
    esac
  done

  # Affichage de l'aide
  if $help_requested; then
    [ "$error_found" = true ] && echo -e "\n\x1b[31m\x1b[2mError: Invalid arguments\x1b[0m\n"
    echo -e "\x1b[1mUsage:\x1b[0m \x1b[2mnscan\x1b[0m"
    echo -e "\x1b[2mScan running Node.js services and show listening ports, working dirs and debug status.\x1b[0m"
    return $([ "$error_found" = true ] && echo 1 || echo 0)
  fi

  echo -e "\x1b[1m======================================================================================"
  echo "                        SCANNER DE SERVICES NODE.JS"
  echo -e "======================================================================================\x1b[0m\n"

  echo -e "\x1b[1mRECHERCHE DES SERVICES NODE.JS...\x1b[0m\n"

  # Récupérer les PIDs
  local NODE_PIDS=()
  local pid
  NODE_PIDS=("${(@f)$(lsof -i -P 2>/dev/null | grep LISTEN | grep -i node | awk '{print $2}' | sort -u)}")

  if [ ${#NODE_PIDS[@]} -eq 0 ]; then
    echo -e "\x1b[33mAucun service Node.js en cours d'exécution n'a été trouvé.\x1b[0m"
    return 0
  fi

  for PID in "${NODE_PIDS[@]}"; do
    local PORTS="" DIRECTORY="" COMMAND="" DEBUG="" DIR_SHORT=""

    PORTS=$(lsof -i -P | grep LISTEN | grep -i node | awk -v pid="$PID" '$2 == pid { split($9, a, ":"); print a[length(a)] }' | head -n 1)
    [ -z "$PORTS" ] && PORTS="–"
    DIRECTORY=$(lsof -p "$PID" 2>/dev/null | grep cwd | awk '{print $9}')
    COMMAND=$(ps -p "$PID" -o command= 2>/dev/null)
    DEBUG="Non"
    [[ "$COMMAND" == *"--inspect"* ]] && DEBUG="Oui"
    DIR_SHORT="${DIRECTORY/#$HOME/~}"

    echo -e "🔍 \x1b[1mPID     :\x1b[0m $PID"
    echo -e "📍 \x1b[1mPorts   :\x1b[0m $PORTS"
    echo -e "📂 \x1b[1mDossier :\x1b[0m $DIR_SHORT"
    echo -e "🐞 \x1b[1mDebug   :\x1b[0m $DEBUG"
    echo -e "🚀 \x1b[1mCommand :\x1b[0m ${COMMAND:0:120}"
    if [ ${#COMMAND} -gt 120 ]; then
      echo -e "             ${COMMAND:120}"
    fi

    echo -e "\n────────────────────────────────────────────────────────────────────────────\n"
  done

  echo -e "🕵️‍♂️ Pour plus de détails : \x1b[2mps -p PID -o pid,ppid,user,command\x1b[0m"
  echo -e "🛑 Pour arrêter un processus : \x1b[2mkill PID\x1b[0m\n"
}

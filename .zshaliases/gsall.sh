# Alias gsall : show git status for all git repositories inside a root folder

unalias gsall 2>/dev/null
gsall() {
  emulate -L zsh
  setopt localoptions noxtrace noverbose
  local OPTIND=1
  local help_requested=false
  local error_found=false
  local args=()
  local staged_only=false
  local fetch_remote=false
  local ROOT
  local has_colors=true
  local summary_clean_no_upstream=0
  local summary_clean_with_upstream=0
  local summary_staged_dirty=0
  local summary_dirty=0

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
      --staged)
        staged_only=true
        ;;
      --fetch)
        fetch_remote=true
        ;;
      *)
        args+=("$arg")
        ;;
    esac
  done

  if [[ ${#args[@]} -gt 1 ]]; then
    echo "\x1b[31mOnly one or no argument accepted\x1b[0m"
    error_found=true
  fi

  ROOT="${args[0]:-.}"

  if ! $help_requested && ! $error_found && [ ! -d "$ROOT" ]; then
    echo "\x1b[31mError: '$ROOT' is not a valid directory.\x1b[0m"
    error_found=true
  fi

  if $help_requested || $error_found; then
    if $error_found; then
      echo "\x1b[31m\x1b[2mError: an error occured\x1b[0m"
      echo ""
    fi

    echo "\x1b[1mUsage:\x1b[0m \x1b[2mgsall [root-dir]\x1b[0m"
    echo "\x1b[2mShow git status for all git repositories found in the given root directory.\x1b[0m"
    echo "\x1b[2mDefault root directory is the current directory (.).\x1b[0m"
    echo "\x1b[2mUse --staged to show only working changes (diff from staged state).\x1b[0m"
    echo "\x1b[2mUse --fetch to run git fetch on each repository before computing ahead/behind.\x1b[0m"
    if $error_found; then
      return 1
    fi

    return 0
  fi

  if [ ! -t 1 ]; then
    has_colors=false
  fi


  local RED GREEN YELLOW BLUE CYAN BOLD DIM NC
  if [ "$has_colors" = true ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    NC='\033[0m'
  else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    BOLD=''
    DIM=''
    NC=''
  fi

  url_encode_path() {
    local raw="$1"
    local encoded

    if command -v python3 >/dev/null 2>&1; then
      encoded="$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$raw" 2>/dev/null)"
      printf '%s' "$encoded"
      return 0
    fi

    return 1
  }

  print_repo_heading() {
    local repo_name="$1"
    local dir="$2"
    local absolute_dir encoded_dir link

    absolute_dir="$(cd "$dir" && pwd)"
    encoded_dir="$(url_encode_path "$absolute_dir" 2>/dev/null || true)"

    if [ -n "$encoded_dir" ]; then
      link="vscode://file/${encoded_dir}"
    else
      link=''
    fi

	printf '\e]8;;%s\a%b[%s]%b\e]8;;\a\n' "$link" "$BOLD$BLUE" "$repo_name" "$NC"
	printf '%s\n' "  Path : \"$absolute_dir\""
  }

  print_repo_status() {
    local dir="$1"
    local repo_name
    local branch
    local upstream
    local ahead=0
    local behind=0
    local porcelain
    local has_changes=false
    local has_staged=false
    local has_working=false
    local status_label
    local status_color
    local ahead_color
    local behind_color

    repo_name="$(basename "$dir")"
    branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
    upstream="$(git -C "$dir" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)"

    if [ "$fetch_remote" = true ]; then
      git -C "$dir" fetch --quiet >/dev/null 2>&1 || true
    fi

    if [ -n "$upstream" ]; then
      local counts
      counts="$(git -C "$dir" rev-list --left-right --count HEAD...@{upstream} 2>/dev/null || echo '0 0')"
      ahead="$(awk '{print $1}' <<< "$counts")"
      behind="$(awk '{print $2}' <<< "$counts")"
    fi

    local has_upstream=false
    if [ -n "$upstream" ]; then
      has_upstream=true
    fi

    porcelain="$(git -C "$dir" status --short --untracked-files=all 2>/dev/null || true)"

    if [ -n "$porcelain" ]; then
      has_changes=true
    fi


    if [ "$has_changes" = true ]; then
      local line
      while IFS= read -r line; do
        [ -z "$line" ] && continue

        if [ "${line:0:1}" != " " ]; then
          has_staged=true
        fi

        if [ "${line:1:1}" != " " ]; then
          has_working=true
        fi
      done <<< "$porcelain"
    fi

    print_repo_heading "$repo_name" "$dir"
    printf '%b\n' "  branch   : ${CYAN}${branch}${NC}"

    ahead_color="$NC"
    behind_color="$NC"

    if [ "$ahead" != "0" ]; then
      ahead_color="$YELLOW"
    fi

    if [ "$behind" != "0" ]; then
      behind_color="$YELLOW"
    fi

    if [ -n "$upstream" ]; then
      printf '%b\n' "  upstream : ${DIM}${upstream}${NC}"
      if [ "$ahead" != "0" ] || [ "$behind" != "0" ]; then
        printf '%b\n' "  sync     : ahead=${ahead_color}${ahead}${NC} behind=${behind_color}${behind}${NC}"
      fi
    else
      printf '%b\n' "  upstream : ${GREEN}up-to-date${NC}"
    fi

    if [ "$has_changes" = false ]; then
      if [ "$has_upstream" = true ] && { [ "$ahead" != "0" ] || [ "$behind" != "0" ]; }; then
        summary_clean_with_upstream=$((summary_clean_with_upstream + 1))
      else
        summary_clean_no_upstream=$((summary_clean_no_upstream + 1))
      fi

      printf '%b\n\n' "  status   : ${GREEN}clean${NC}"
      return
    fi

    if [ "$has_working" = true ]; then
      status_label="dirty"
      status_color="$RED"
      summary_dirty=$((summary_dirty + 1))
    else
      status_label="staged dirty"
      status_color="$YELLOW"
      summary_staged_dirty=$((summary_staged_dirty + 1))
    fi

    printf '%b\n\n' "  status   : ${status_color}${status_label}${NC}"

    print_change_line() {
      local section="$1"
      local line="$2"
      local index_status worktree_status raw_path file_path old_path label color status_code

      [ -z "$line" ] && return

      index_status="${line:0:1}"
      worktree_status="${line:1:1}"
      raw_path="${line:3}"
      file_path="$raw_path"
      old_path=''
      label='changed'
      color="$YELLOW"

      if [ "$section" = "staged" ]; then
        status_code="$index_status"
      else
        status_code="$worktree_status"
      fi

      case "$status_code" in
        M)
          label="modified"
          color="$YELLOW"
          ;;
        A)
          label="added"
          color="$GREEN"
          ;;
        D)
          label="deleted"
          color="$RED"
          ;;
        R)
          label="renamed"
          color="$CYAN"
          ;;
        C)
          label="copied"
          color="$CYAN"
          ;;
        U)
          label="conflict"
          color="$RED"
          ;;
        \?)
          label="untracked"
          color="$RED"
          ;;
        *)
          return
          ;;
      esac

      if [[ "$file_path" == *" -> "* ]]; then
        old_path="${file_path%% -> *}"
        file_path="${file_path##* -> }"
        printf '%b\n' "    - ${color}${label}${NC}: ${old_path} ${DIM}->${NC} ${file_path}"
      else
        printf '%b\n' "    - ${color}${label}${NC}: ${file_path}"
      fi
    }

    local printed_changes=false

    if [ "$staged_only" = false ] && [ "$has_staged" = true ]; then
      printf '%s\n' "  staged changes :"
      while IFS= read -r line; do
        print_change_line "staged" "$line"
      done <<< "$porcelain"
      printed_changes=true
    fi

    if [ "$has_working" = true ]; then
      printf '%s\n' "  working changes:"
      while IFS= read -r line; do
        print_change_line "working" "$line"
      done <<< "$porcelain"
      printed_changes=true
    fi

    if [ "$printed_changes" = true ]; then
      printf '\n'
    fi
  }

  local found_any=false
  local dir

  for dir in "$ROOT"/*; do
    [ -d "$dir" ] || continue
    [ -d "$dir/.git" ] || continue
    found_any=true

    print_repo_status "$dir"
  done

  if [ "$found_any" = false ]; then
    echo "No git repositories found in: $ROOT"
    return 0
  fi

  printf '%b\n' "${BOLD}Summary${NC}"
  printf '%b\n' "  ${GREEN}clean / no upstream${NC} : ${summary_clean_no_upstream}"
  printf '%b\n' "  ${CYAN}clean / with upstream${NC} : ${summary_clean_with_upstream}"
  printf '%b\n' "  ${YELLOW}staged dirty${NC} : ${summary_staged_dirty}"
  printf '%b\n' "  ${RED}dirty${NC} : ${summary_dirty}"
}

# Alias gsall : show git status for all git repositories inside a root folder

unalias gsall 2>/dev/null

gsall() {
  emulate -L zsh
  setopt localoptions noxtrace noverbose

  local help_requested=false
  local error_found=false
  local staged_only=false
  local brief_only=false
  local fetch_remote=false
  local ROOT='.'
  local -a positional_args=()

  local summary_clean_no_upstream=0
  local summary_clean_with_upstream=0
  local summary_staged_dirty=0
  local summary_dirty=0

  local -a summary_clean_no_upstream_repos=()
  local -a summary_clean_with_upstream_repos=()
  local -a summary_staged_dirty_repos=()
  local -a summary_dirty_repos=()

  local has_colors=true
  if [ ! -t 1 ]; then
    has_colors=false
  fi

  local RED GREEN YELLOW BLUE MAGENTA CYAN BOLD DIM NC
  if [ "$has_colors" = true ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    NC='\033[0m'
  else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    MAGENTA=''
    CYAN=''
    BOLD=''
    DIM=''
    NC=''
  fi

  print_help() {
    echo "\x1b[1mUsage:\x1b[0m \x1b[2mgsall [folder] [--staged] [--fetch] [--brief]\x1b[0m"
    echo "\x1b[2mShow git status for all git repositories found in the given root directory.\x1b[0m"
    echo "\x1b[2mDefault root directory is the current directory (.).\x1b[0m"
    echo "\x1b[2mUse --staged to show only working changes (diff from staged state).\x1b[0m"
    echo "\x1b[2mUse --fetch to run git fetch on each repository before computing ahead/behind.\x1b[0m"
    echo "\x1b[2mUse --brief to show only the summary, with repo names listed for each category.\x1b[0m"
    echo "\x1b[2mShort flags are supported: -s, -f, -b, -h, as well as combined forms like -sf, -fs, -bf or -bfs.\x1b[0m"
    echo "\x1b[2mThe folder argument defaults to the current directory (.).\x1b[0m"
  }

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
      printf '\e]8;;%s\a%b[%s]%b\e]8;;\a\n' "$link" "$BOLD$BLUE" "$repo_name" "$NC"
    else
      printf '%b\n' "${BOLD}${BLUE}[$repo_name]${NC}"
    fi

    printf '%s\n' "  Path : \"$absolute_dir\""
  }

  format_repo_link() {
    local dir="$1"
    local repo_name="$2"
    local absolute_dir encoded_dir link

    absolute_dir="$(cd "$dir" && pwd)"
    encoded_dir="$(url_encode_path "$absolute_dir" 2>/dev/null || true)"

    if [ -n "$encoded_dir" ]; then
      link="vscode://file/${encoded_dir}"
      printf '\e]8;;%s\a[%s]\e]8;;\a' "$link" "$repo_name"
    else
      printf '[%s]' "$repo_name"
    fi
  }

  print_repo_list_line() {
    local label="$1"
    local item_color="$2"
    local count="$3"
    shift 3
    local -a repos=("$@")
    local item
    local first=true

    printf '%b : %s' "$label" "$count"

    if [ "$brief_only" = true ] && [ "${#repos[@]}" -gt 0 ]; then
      printf ' '
      for item in "${repos[@]}"; do
        if [ "$first" = true ]; then
          first=false
        else
          printf ', '
        fi
        printf '%b' "$item_color"
        format_repo_link "$ROOT/$item" "$item"
        printf '%b' "$NC"
      done
    fi

    printf '\n'
  }

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
        color="$MAGENTA"
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

  local arg
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
      --brief)
        brief_only=true
        ;;
      --)
        ;;
      -*)
        if [[ "$arg" == --* ]]; then
          echo "\x1b[31mUnknown option: ${arg}\x1b[0m"
          error_found=true
          continue
        fi

        local short_flags="${arg#-}"
        local i
        local short_flag
        for (( i = 1; i <= ${#short_flags}; i++ )); do
          short_flag="${short_flags[$i]}"
          case "$short_flag" in
            h)
              help_requested=true
              ;;
            s)
              staged_only=true
              ;;
            f)
              fetch_remote=true
              ;;
            b)
              brief_only=true
              ;;
            *)
              echo "\x1b[31mUnknown option: -${short_flag}\x1b[0m"
              error_found=true
              ;;
          esac
        done
        ;;
      *)
        positional_args+=("$arg")
        ;;
    esac
  done

  if [[ ${#positional_args[@]} -gt 1 ]]; then
    echo "\x1b[31mOnly one or no argument accepted\x1b[0m"
    error_found=true
  fi

  if [[ ${#positional_args[@]} -eq 1 ]]; then
    ROOT="${positional_args[1]}"
  fi

  if ! $help_requested && ! $error_found; then
    if [ ! -d "$ROOT" ]; then
      echo "\x1b[31mError: '$ROOT' is not a valid directory.\x1b[0m"
      error_found=true
    else
      local has_git_subdirs=false
      local candidate_dir
      for candidate_dir in "$ROOT"/*; do
        [ -d "$candidate_dir" ] || continue
        [ -d "$candidate_dir/.git" ] || continue
        has_git_subdirs=true
        break
      done

      if [ "$has_git_subdirs" = false ]; then
        echo "\x1b[31mError: '$ROOT' does not contain any git subdirectories.\x1b[0m"
        error_found=true
      fi
    fi
  fi

  if $help_requested || $error_found; then
    if $error_found; then
      echo "\x1b[31m\x1b[2mError: an error occured\x1b[0m"
      echo ""
    fi

    print_help

    if $error_found; then
      return 1
    fi

    return 0
  fi

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
    local has_upstream=false
    local status_label
    local status_color
    local ahead_color
    local behind_color
    local line
    local counts
    local has_remote_diff=false

    repo_name="$(basename "$dir")"
    branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
    upstream="$(git -C "$dir" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)"

    if [ "$fetch_remote" = true ]; then
      echo "Fetching ${repo_name}..."
      git -C "$dir" fetch --quiet >/dev/null 2>&1 || true
    fi

    if [ -n "$upstream" ]; then
      has_upstream=true
      counts="$(git -C "$dir" rev-list --left-right --count HEAD...@{upstream} 2>/dev/null || echo '0 0')"
      ahead="$(awk '{print $1}' <<< "$counts")"
      behind="$(awk '{print $2}' <<< "$counts")"
    fi

    ahead_color="$NC"
    behind_color="$NC"

    if [ "$ahead" != "0" ]; then
      ahead_color="$YELLOW"
    fi

    if [ "$behind" != "0" ]; then
      behind_color="$YELLOW"
    fi

    if [ "$ahead" != "0" ] || [ "$behind" != "0" ]; then
      has_remote_diff=true
    fi

    porcelain="$(git -C "$dir" status --short --untracked-files=all 2>/dev/null || true)"

    if [ -n "$porcelain" ]; then
      has_changes=true
    fi

    if [ "$has_changes" = true ]; then
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

    if [ "$brief_only" = false ]; then
      print_repo_heading "$repo_name" "$dir"
      printf '%b\n' "  branch   : ${CYAN}${branch}${NC}"

      if [ -n "$upstream" ]; then
        if [ "$has_remote_diff" = true ]; then
          printf '%b\n' "  upstream : ${DIM}${upstream}${NC}"
          printf '%b\n' "  sync     : ahead=${ahead_color}${ahead}${NC} behind=${behind_color}${behind}${NC}"
        else
          printf '%b\n' "  upstream : ${GREEN}up-to-date${NC}"
        fi
      else
        printf '%b\n' "  upstream : ${DIM}no tracking branch${NC}"
      fi
    fi

    if [ "$has_changes" = false ]; then
      if [ "$has_upstream" = true ] && [ "$has_remote_diff" = true ]; then
        summary_clean_with_upstream=$((summary_clean_with_upstream + 1))
        summary_clean_with_upstream_repos+=("$repo_name")
      else
        summary_clean_no_upstream=$((summary_clean_no_upstream + 1))
        summary_clean_no_upstream_repos+=("$repo_name")
      fi

      if [ "$brief_only" = false ]; then
        printf '%b\n\n' "  status   : ${GREEN}clean${NC}"
      fi
      return
    fi

    if [ "$has_working" = true ]; then
      status_label="dirty"
      status_color="$RED"
      summary_dirty=$((summary_dirty + 1))
      summary_dirty_repos+=("$repo_name")
    else
      status_label="staged dirty"
      status_color="$YELLOW"
      summary_staged_dirty=$((summary_staged_dirty + 1))
      summary_staged_dirty_repos+=("$repo_name")
    fi

    if [ "$brief_only" = false ]; then
      printf '%b\n' "  status   : ${status_color}${status_label}${NC}"
    fi

    if [ "$brief_only" = true ]; then
      return
    fi

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

    printf '\n'
  }

  local found_any=false
  local dir
  printf '\n'
  printf '%b\n' "${MAGENTA}${BOLD}  ██████${NC}${BOLD}╗ ${MAGENTA}███████${NC}${BOLD}╗ ${MAGENTA}█████${NC}${BOLD}╗ ${MAGENTA}██${NC}${BOLD}╗     ${MAGENTA}██${NC}${BOLD}╗${NC}"
  printf '%b\n' "${MAGENTA}${BOLD} ██${NC}${BOLD}╔════╝ ${MAGENTA}██${NC}${BOLD}╔════╝${MAGENTA}██${NC}${BOLD}╔══${MAGENTA}██${NC}${BOLD}╗${MAGENTA}██${NC}${BOLD}║     ${MAGENTA}██${NC}${BOLD}║${NC}"
  printf '%b\n' "${MAGENTA}${BOLD} ██${NC}${BOLD}║  ${MAGENTA}███${NC}${BOLD}╗${MAGENTA}███████${NC}${BOLD}╗${MAGENTA}███████${NC}${BOLD}║${MAGENTA}██${NC}${BOLD}║     ${MAGENTA}██${NC}${BOLD}║${NC}"
  printf '%b\n' "${MAGENTA}${BOLD} ██${NC}${BOLD}║   ${MAGENTA}██${NC}${BOLD}║╚════${MAGENTA}██${NC}${BOLD}║${MAGENTA}██${NC}${BOLD}╔══${MAGENTA}██${NC}${BOLD}║${MAGENTA}██${NC}${BOLD}║     ${MAGENTA}██${NC}${BOLD}║${NC}"
  printf '%b\n' "${MAGENTA}${BOLD} ${NC}${BOLD}╚${MAGENTA}██████${NC}${BOLD}╔╝${MAGENTA}███████${NC}${BOLD}║${MAGENTA}██${NC}${BOLD}║  ${MAGENTA}██${NC}${BOLD}║${MAGENTA}███████${NC}${BOLD}╗${MAGENTA}███████${NC}${BOLD}╗${NC}"
  printf '%b\n' "${NC}${BOLD}  ╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝${NC}"

  printf '%b\n\n' "${DIM}  Git status all repositories in $ROOT/*${NC}"

  local nbprojects=0
  for dir in "$ROOT"/*; do
    [ -d "$dir" ] || continue
    [ -d "$dir/.git" ] || continue
    found_any=true
    print_repo_status "$dir"
    nbprojects=$((nbprojects + 1))
  done

  if [ "$found_any" = false ]; then
    echo "No git repositories found in: $ROOT"
    return 0
  fi

  printf '%b\n' "${BOLD}Summary${NC} (${nbprojects} projects)"
  print_repo_list_line "  ${GREEN}clean / no upstream${NC}" "$GREEN" "$summary_clean_no_upstream" "${summary_clean_no_upstream_repos[@]}"
  print_repo_list_line "  ${CYAN}clean / with upstream${NC}" "$CYAN" "$summary_clean_with_upstream" "${summary_clean_with_upstream_repos[@]}"
  print_repo_list_line "  ${YELLOW}staged dirty${NC}" "$YELLOW" "$summary_staged_dirty" "${summary_staged_dirty_repos[@]}"
  print_repo_list_line "  ${RED}dirty${NC}" "$RED" "$summary_dirty" "${summary_dirty_repos[@]}"

  printf '\n'
}

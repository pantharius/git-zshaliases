#!/bin/zsh

has_colors=false
if [ -t 1 ]; then
  has_colors=true
fi

if [ "$has_colors" = true ]; then
  NC='\033[0m'
  BOLD='\033[1m'
  BLACK='\033[30m'
  RED='\033[31m'
  GREEN='\033[32m'
  YELLOW='\033[33m'
  BLUE='\033[34m'
  MAGENTA='\033[35m'
  CYAN='\033[36m'
  WHITE='\033[37m'
else
  NC=''
  BOLD=''
  BLACK=''
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  MAGENTA=''
  CYAN=''
  WHITE=''
fi

color_value() {
  local color_name="$1"

  case "$color_name" in
    black) printf '%s' "$BLACK" ;;
    red) printf '%s' "$RED" ;;
    green) printf '%s' "$GREEN" ;;
    yellow) printf '%s' "$YELLOW" ;;
    blue) printf '%s' "$BLUE" ;;
    magenta) printf '%s' "$MAGENTA" ;;
    cyan) printf '%s' "$CYAN" ;;
    white) printf '%s' "$WHITE" ;;
    bold) printf '%s' "$BOLD" ;;
    rgb:*)
      if [ "$has_colors" != true ]; then
        printf ''
        return 0
      fi

      local rgb_values="${color_name#rgb:}"
      local r="${rgb_values%%,*}"
      local rest="${rgb_values#*,}"
      local g="${rest%%,*}"
      local b="${rest#*,}"
      printf '\033[38;2;%s;%s;%sm' "$r" "$g" "$b"
      ;;
    none|'') printf '' ;;
    *) printf '' ;;
  esac
}

bg_color_value() {
  local color_name="$1"

  if [ "$has_colors" != true ]; then
    printf ''
    return 0
  fi

  case "$color_name" in
    black) printf '\033[40m' ;;
    red) printf '\033[41m' ;;
    green) printf '\033[42m' ;;
    yellow) printf '\033[43m' ;;
    blue) printf '\033[44m' ;;
    magenta) printf '\033[45m' ;;
    cyan) printf '\033[46m' ;;
    white) printf '\033[47m' ;;
    rgb:*)
      local rgb_values="${color_name#rgb:}"
      local r="${rgb_values%%,*}"
      local rest="${rgb_values#*,}"
      local g="${rest%%,*}"
      local b="${rest#*,}"
      printf '\033[48;2;%s;%s;%sm' "$r" "$g" "$b"
      ;;
    none|'') printf '' ;;
    *) printf '' ;;
  esac
}

render_multi_colored_ascii() {
  local rules_end_index=0
  local arg

  for (( rules_end_index = 1; rules_end_index <= $#; rules_end_index++ )); do
    arg="${@[rules_end_index]}"
    if [ "$arg" = '--' ]; then
      break
    fi
  done

  local -a rules lines
  rules=("${@:1:$((rules_end_index - 1))}")
  lines=("${@:$((rules_end_index + 1))}")

  local -a rule_chars rule_fg_codes rule_bg_codes
  local rule
  local -a rule_parts

  for rule in "${rules[@]}"; do
    rule_parts=(${(s:|:)rule})
    rule_chars+=("${rule_parts[1]}")
    rule_fg_codes+=("$(color_value "${rule_parts[2]}")")
    rule_bg_codes+=("$(bg_color_value "${rule_parts[3]}")")
  done

  local output=''
  local line raw_char matched=false
  local fg_code bg_code

  for line in "${lines[@]}"; do
    local output_line=''

    for (( i = 1; i <= ${#line}; i++ )); do
      raw_char="${line[$i]}"
      matched=false

      for (( j = 1; j <= ${#rule_chars[@]}; j++ )); do
        if [[ "${rule_chars[$j]}" == *"$raw_char"* ]]; then
          fg_code="${rule_fg_codes[$j]}"
          bg_code="${rule_bg_codes[$j]}"
          output_line+="${bg_code}${fg_code}${BOLD}${raw_char}${NC}"
          matched=true
          break
        fi
      done

      if [ "$matched" != true ]; then
        output_line+="$raw_char"
      fi
    done

    output+="$output_line\n"
  done

  printf '%b' "$output"
}

render_colored_ascii() {
  local fill_char="$1"
  local fg_name="$2"
  local bg_name="$3"
  shift 3

  render_multi_colored_ascii "${fill_char}|${fg_name}|${bg_name}" -- "$@"
}

printf '\n'
render_multi_colored_ascii '█|rgb:201,17,203|none' '░|rgb:203,17,112|none' -- \
  ' ██████   █████ ██████████  █████████  ███████████    ███████    ███████████     ' \
  '░░██████ ░░███ ░░███░░░░░█ ███░░░░░███░█░░░███░░░█  ███░░░░░███ ░░███░░░░░███    ' \
  ' ░███░███ ░███  ░███  █ ░ ░███    ░░░ ░   ░███  ░  ███     ░░███ ░███    ░███    ' \
  ' ░███░░███░███  ░██████   ░░█████████     ░███    ░███      ░███ ░██████████     ' \
  ' ░███ ░░██████  ░███░░█    ░░░░░░░░███    ░███    ░███      ░███ ░███░░░░░███    ' \
  ' ░███  ░░█████  ░███ ░   █ ███    ░███    ░███    ░░███     ███  ░███    ░███    ' \
  ' █████  ░░█████ ██████████░░█████████     █████    ░░░███████░   █████   █████   ' \
  '░░░░░    ░░░░░ ░░░░░░░░░░  ░░░░░░░░░     ░░░░░       ░░░░░░░    ░░░░░   ░░░░░    '
printf '\n'

printf '%b\n' "${GREEN}${BOLD}Hey - bon courage pour la suite.${NC}"
printf '%b\n\n' "${WHITE}Que ton terminal soit calme, et tes commandes efficaces.${NC}"
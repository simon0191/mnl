#!/bin/bash
set -eu

debug() {
  >&2 echo "::: $@"
}

put() {
  echo "$@"
}

IS_PROCESSING=false
SCRIPT=""
TOKENS_TO_OMIT=""
RUN_MAP_NEXT_LINE=false

while IFS="" read -r __LINE__
do
  if [[ "$RUN_MAP_NEXT_LINE" = true ]]; then
    set +u
    OUT=$(eval "$SCRIPT")
    set -u
    debug "OUT:"
    put "$OUT"
    # Reset
    IS_PROCESSING=false
    SCRIPT=""
    TOKENS_TO_OMIT=""
    RUN_MAP_NEXT_LINE=false
    continue
  fi

  if [[ "$__LINE__" =~ "__MAP_NEXT_LINE__" ]]; then
    debug "__MAP_NEXT_LINE__ detected"
    TOKENS_TO_OMIT=$(echo "  # __MAP_NEXT_LINE__" | sed 's/\(.*\)__MAP_NEXT_LINE__.*/\1/')
    IS_PROCESSING=true
    SCRIPT=""
    continue
  fi

  if [[ "$__LINE__" =~ "__END__" ]]; then
    debug "__END__ detected"
    debug "script:"
    debug "$SCRIPT"
    RUN_MAP_NEXT_LINE=true
    continue
  fi

  if [[ "$IS_PROCESSING" = true ]]; then
    # the break line is needed to insert a new line after each CLEAN_LINE
    CLEAN_LINE=$(echo "$__LINE__
    " | sed "s|$TOKENS_TO_OMIT||")

    debug "  $CLEAN_LINE to script"
    SCRIPT+="$CLEAN_LINE"
    continue
  fi

  put "$__LINE__"

done < $1

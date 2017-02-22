#!/bin/bash

trap exit INT TERM EXIT;

if [ -z BUNDLE_PATH ]; then
  export BUNDLE_PATH=/bundle
fi
export PATH=$PATH:/tmp/bin

log () {
  CNT=${#1}
  node -p "'___' + (new Array($CNT)).join('_')"
  echo "\$ $1"
  echo ""
}

run () {
  log "$1"
  $1
}

TMP=/usr/src/app/tmp
mkdir -p ${TMP}/out

read_new_lines () {
  if [ ! -f $1 ]; then
    return
  fi
  readarray outlines <$1
  LINE_NR=0
  for line in "${outlines[@]}"; do
    ((LINE_NR=LINE_NR+1))
    if [ ${LINE_NR} -gt ${LINES_READ} ]; then
      export LINES_READ=${LINE_NR}
      printf "${line}"
    fi
  done
}

parallel_by_line () {
  CNT=0
  readarray lines
  for line in "${lines[@]}"; do
    (echo "$line" | /bin/bash) >${TMP}/out/parallel_${CNT}.out 2>${TMP}/out/parallel_${CNT}.err &
    PIDS="$PIDS $!"
    ((CNT=CNT+1))
  done

  CNT=0
  ERROR=false
  for pid in $PIDS; do
    if [ ${ERROR} != "true" ]; then
      export LINES_READ=0
      while [ -e /proc/$pid ]; do
        read_new_lines ${TMP}/out/parallel_${CNT}.out
      done
      read_new_lines ${TMP}/out/parallel_${CNT}.out
      cat ${TMP}/out/parallel_${CNT}.err >&2
      wait $pid || ERROR=true
    else
      kill $pid >/dev/null 2>&1
    fi
    rm ${TMP}/out/parallel_${CNT}.*
    ((CNT=CNT+1))
  done
  if [ ${ERROR} == "true" ]; then
    return 1
  fi
}

rm ${TMP}/pids/server.pid 2>/dev/null

log "$0"
(cat <<TASKS
  echo "▶︎ pwd:         `pwd`"
  echo "▶︎ PATH:        ${PATH}"
  echo "▶︎ BUNDLE_PATH: ${BUNDLE_PATH}"
  echo "▶︎ bundler:     `bundle --version`"
  echo "▶︎ gem:         `gem --version`"
  echo "▶︎ ruby:        `ruby --version`"
  echo "▶︎ node:        `node --version`"
  echo "▶︎ yarn:        `yarn --version`"
  echo "▶︎ python:      $(python -c 'from platform import python_version; print python_version()')"
  echo ""
  echo "⦿ Installing node dependencies"
  echo ""
  yarn install --no-emoji --ignore-optional --strict-semver --network-concurrency=15
  echo ""
  echo "⦿ Installing gems"
  echo ""
  bundle check || bundle install
  echo ""
TASKS
) | parallel_by_line || exit 1

run "$@" || exit 1

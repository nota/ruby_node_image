#!/bin/bash

trap exit INT TERM EXIT;


log () {
  CNT=${#1}
  node -p "'___' + (new Array($CNT)).join('_')"
  echo "\$ $1"
  echo ""
}

log "$0"
echo "» pwd:         `pwd`"
echo "» PATH:        ${PATH}"
echo "» BUNDLE_PATH: ${BUNDLE_PATH}"
echo "» bundler:     `bundle --version`"
echo "» gem:         `gem --version`"
echo "» ruby:        `ruby --version`"
echo "» node:        `node --version`"
echo "» yarn:        `yarn --version`"
echo "» python:      $(python -c 'from platform import python_version; print python_version()')"

# some restarts don't kill the server
rm /usr/src/app/tmp/pids/server.pid 2>/dev/null

log "bundle check || bundle install"
bundle check || bundle install

log "yarn install --no-emoji --ignore-optional --strict-semver --network-concurrency=15"
yarn install --no-emoji --ignore-optional --strict-semver --network-concurrency=15

CNT=${#@}

log "$@"
$@

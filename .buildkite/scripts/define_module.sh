#!/usr/bin/env bash

set -euo pipefail

OSS_MODULE_PATTERN="^[a-z0-9]+beat\\/module\\/([^\\/]+)\\/.*"
XPACK_MODULE_PATTERN="^x-pack\\/[a-z0-9]+beat\\/module\\/([^\\/]+)\\/.*"

definePattern() {
  pattern="${OSS_MODULE_PATTERN}"

  if [[ "$beatPath" == *"x-pack/"* ]]; then
    pattern="${XPACK_MODULE_PATTERN}"
  fi

  echo "--- With MODULE Pattern: $pattern"
}

defineExclusions() {
  local transformedDirectory=${beatPath//\//\\\/}
  local exclusion="((?!^${transformedDirectory}\\/).)*\$"
  exclude="^(${exclusion}|((?!\\/module\\/).)*\$|.*\\.asciidoc|.*\\.png)"

  echo "--- With MODULE Exclusions: $exclude"
}

defineFromCommit() {
  local previousCommit
  local changeTarget=${BUILDKITE_PULL_REQUEST_BASE_BRANCH:-$BUILDKITE_BRANCH}

  previousCommit=$(git rev-parse HEAD^)

  from=${changeTarget:+"origin/$changeTarget"}
  from=${from:-$previousCommit}
  from=${from:-$BUILDKITE_COMMIT}
}

getMatchingModules() {
  local changedPaths
  defineFromCommit

  echo "--- From BRANCH is: $from"
  echo "--- Git Diff: $(git diff --name-only "$from"..."$BUILDKITE_COMMIT")"

  mapfile -t changedPaths < <(git diff --name-only "$from"..."$BUILDKITE_COMMIT" | grep -v "$exclude")

   for path in "${changedPaths[@]}"; do
    echo "--- PATH FOUND: $path"
  done

  mapfile -t changedPaths < <(git diff --name-only "$from"..."$BUILDKITE_COMMIT" | grep -v "$exclude" | grep -oE "$pattern" | sort -u)
}

addModule() {
  local module=$1
  if [ "$modules" != "" ]; then
    modules+=","
  fi
    modules+="$(basename "$module")"

  echo "--- Modules Added: $modules"
}

defineModule() {
  beatPath=$1
  modules=''

  definePattern
  defineExclusions
  getMatchingModules

  for path in "${changedPaths[@]}"; do
    echo "--- PATH FOUND: $path"
  done

#  export NEW_MODULE=$modules
}

#!/bin/bash

# This script finds the latest tagged release for a repo and
# compares this with a target commit.

STATE_FILE=${PWD}/pipeline-state.env
set -e

REPO_URL=$1
TARGET_VERSION=$2

if [ "$REPO_URL" = "" ] || [ "$TARGET_VERSION" = "" ]; then
  >&2 printf "\
Usage: \n\n\
$0 repository_url target_version \n\
  repository_url             Git repository URL \n\
  target_version             The SHA, branch or tag to compare to\n\n"
  exit 1
fi

# Find the latest release using the format NUM.NUM.NUM. Anything else, like "1.2.3-pre" is assumed to not be a relase tag and is excluded
# Redirect STDERR to /dev/null as it will print out the Git remote URL including the access token
LATEST_RELEASE=`git ls-remote --tags 2>/dev/null | awk -F '/' '{print $3}' | grep -e '^[0-9]\+\.[0-9]\+.[0-9]\+$' | sort --version-sort | tail -1`

COMMIT_LOG=`git log -1`

declare -A changedModules

find . -maxdepth 1 -type d -not -path "./.*" | awk -F '/' '{print $2}' | grep -ve "^$" > /tmp/changed-paths
while read -r module
do
  changedModules[${module}]=false
done < /tmp/changed-paths

if [ "$LATEST_RELEASE" = "" ]; then
  >&2 echo "No previous tagged release found. Changed folder assumed to be everything (.)"
  for key in "${!changedModules[@]}"; do
    changedModules[${key}]=true
  done
else
  >&2 git checkout -b base                                     # Create a branch for our base state
  >&2 git fetch origin --depth 1 $LATEST_RELEASE               # Fetch the single commit for the base of our comparison
  >&2 git reset --hard FETCH_HEAD                              # Point the local master to the commit we just fetched

  >&2 git checkout -b target                                   # Create a branch for our target state

  >&2 git fetch origin --depth 1 $TARGET_VERSION               # Fetch the single commit for the target of our comparison
  >&2 git reset --hard FETCH_HEAD                              # Point the local target to the commit we just fetched

  # Determine modules with files changed between the two commits
  git diff --name-only base target | grep / | awk 'BEGIN {FS="/"} {print $1}' | uniq | while read -r module
    do
      changedModules[${module}]=true
    done
fi

export ORIGINAL_CODEBUILD_SOURCE_VERSION=${CODEBUILD_SOURCE_VERSION}

echo > ${STATE_FILE}
for var in changedModules CODEBUILD_BUILD_ID COMMIT_LOG ORIGINAL_CODEBUILD_SOURCE_VERSION; do
cat >> ${STATE_FILE} << EOF
$(declare -p ${var})
export ${var}
EOF
done

echo done with state $(cat ${STATE_FILE})

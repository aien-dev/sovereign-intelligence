#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Failure notice for the nightly E2E run (DRA-59): comments on the open issue labelled
# nightly-failure, or opens one, mentioning the maintainer and linking the failed run.
# Needs gh with GH_TOKEN (the job's GITHUB_TOKEN, permissions issues: write) and GH_REPO set.
#   MAINTAINER=login RUN_URL=url sh installer/rig/notify-failure.sh
set -eu
: "${GH_REPO:?}" "${MAINTAINER:?}" "${RUN_URL:?}"
label=nightly-failure
body="@$MAINTAINER the nightly E2E run failed: $RUN_URL"
num=$(gh issue list --label "$label" --state open --limit 1 --json number --jq '.[0].number // empty')
if [ -n "$num" ]; then
	gh issue comment "$num" --body "$body"
else
	gh label create "$label" --color B60205 --description "Nightly E2E run failed" --force
	gh issue create --title "Nightly E2E run failing" --label "$label" --assignee "$MAINTAINER" --body "$body"
fi

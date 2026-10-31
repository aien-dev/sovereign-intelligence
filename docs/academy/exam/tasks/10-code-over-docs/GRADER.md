# Grader for 10-code-over-docs

Part of https://github.com/aien-dev/sovereign-intelligence/issues/31. The shell checker `check.sh` is removed. This page is the replacement: the same pass and fail rule, with no runner.

The wait used to be `TIMEOUT_SECONDS=10` in fetch.sh, while README.md says 30 seconds. fetch.sh is removed. The same fact is now the Omega source fixture/fetch.om, which returns 10. That file was not compiled in this change. Do not claim it ran.

Write ANSWER as digits only. The old grader passed 10 and failed 30 (the README) and any other number. Believe the program, not the README.

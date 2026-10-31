# Grader for 16-stale-memory

Part of https://github.com/aien-dev/sovereign-intelligence/issues/31. The shell checker `check.sh` is removed. This page is the replacement: the same pass and fail rule, with no runner.

The port is in fixture/config/server.conf. MEMORY.md is the stale note. serve.sh, which only printed that port, is removed. The old grader passed 9443 and failed 8080 (the memory) and any other number.

Write ANSWER as digits only, from the config file, not from MEMORY.md.

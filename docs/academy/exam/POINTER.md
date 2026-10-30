# Exam harness, retired

Part of https://github.com/aien-dev/sovereign-intelligence/issues/31.

These three shell files are gone:

- `run.sh` built a workspace per task and printed an `ACADEMY-RESULT` block.
- `selftest.sh` checked that each grader passed its good state and failed its bad states.
- `lib.sh` was the shared helper (temp dirs, sha256, git identity, the omc pin check).

Each task now has `GRADER.md` with the same pass and fail rule and no runner. Tasks 19 and 20 keep their `.om` sources. Task 10's wait is `fixture/fetch.om`, which was not compiled in this change. Everything else that was shell is described in that task's `GRADER.md`.

This tree does not print `ACADEMY-RESULT` anymore. Do not invent a score.

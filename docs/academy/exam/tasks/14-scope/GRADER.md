# Grader for 14-scope

Part of https://github.com/aien-dev/sovereign-intelligence/issues/31. The shell checker `check.sh` is removed. This page is the replacement: the same pass and fail rule, with no runner.

The task was to rename the shell function trimws to trim_space in the three files that defined or called it, and nowhere else. Those shell files, and the expected/ copies, are removed. The old grader compared the workspace file list with the fixture and required the three callers to match expected/ and every other file to be unchanged.

What to do now: write NOTES.md naming the rename and stating that you did not edit a shell tree, because that tree is gone. Do not claim a diff you did not make. fixture/README.md remains.

# Grader for 07-evidence-level

Part of https://github.com/aien-dev/sovereign-intelligence/issues/31. The shell checker `check.sh` is removed. This page is the replacement: the same pass and fail rule, with no runner.

Read fixture/scenarios.txt and write ANSWERS.txt, one line per scenario: number, space, level. The old grader required exactly:

1 PROPOSED
2 IMPLEMENTED
3 EXERCISED
4 EXERCISED
5 QUALIFIED
6 IMPLEMENTED

The shell checker is gone. The scenarios and the reference ANSWERS.txt files under selftest/ remain. Grade by comparing with that list. Do not raise a level the scenario did not earn.

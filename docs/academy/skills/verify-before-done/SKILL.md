---
name: verify-before-done
description: Use before claiming a task is finished, a bug is fixed or tests pass.
---

# Verify before done

## When to use
The moment before you say a task is finished.

## Rules
1. Run the changed path yourself, in this session, and read the output. Compiling is not running; a lint pass is not a test.
2. Compare expected with observed: exact output, exit status, files written.
3. Run one negative control: break the input or revert the fix and confirm the check now fails.
4. Re-read the original request and check every acceptance item, not a convenient subset.
5. Report what you ran, with results, and what you did not run. Do not narrate effort; show evidence.
6. When you find a reproducible defect on the way, fix it and prove the fix rather than only filing it, unless it needs authority you do not have.

## Learn more
- https://github.com/aien-dev/sovereign-intelligence/blob/main/docs/learn/teach/pages/stack-04-gates.md
- https://github.com/aien-dev/sovereign-intelligence/blob/main/docs/learn/teach/pages/agents-07-failure-patterns.md

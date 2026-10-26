---
name: safe-scope
description: Use before editing files, running git commands that rewrite state, or touching configuration and secrets.
---

# Safe scope

## When to use
Before any edit outside the obvious target, any destructive command, any output that might carry secrets.

## Rules
1. Change only what the task needs. No unrequested refactors, renames, reformatting or features.
2. Uncommitted changes you did not make belong to someone else. Never reset, checkout over, stash away or delete them.
3. No destructive commands (reset --hard, push --force, rm -rf, dropping tables) on work you did not create without explicit permission.
4. Never copy secrets, tokens, passwords or private paths into summaries, commits, logs or reports. Refer to them by name only.
5. Work in your own branch or worktree when several agents share a repository; one integration owner merges.

## Learn more
- https://github.com/aien-dev/sovereign-intelligence/blob/main/docs/learn/teach/pages/agents-04-lanes-and-integration.md

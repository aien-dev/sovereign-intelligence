# Lanes and integration owners: many agents, one shared surface

Evidence level: EXERCISED. The lane and merge sequence ran with git in a throwaway repository on a Linux host; it shows the mechanics, not a measured multi-agent run.

## Goal

Run several agents in parallel without them corrupting each other's work, and know who merges.

## Explanation

On a busy day I have a dozen or more agents working at once. That only works with three rules.

**1. One lane, one isolated tree.** Every agent works in its own clone or git worktree, on its own branch, pinned to a known commit. Never in a shared checkout. An agent never checks out, resets, stashes or cleans in a tree another agent is using, and never reads another agent's uncommitted files as if they were the project. Uncommitted work belongs to its owner until the owner commits it.

**2. One integration owner per shared surface.** Anything two lanes both touch (a shared document, an index file, a release, a pull request that bundles lanes) has exactly one owner. Lanes hand the owner committed branches. The owner merges, runs the combined check, and opens the pull request. Two agents both "helping" with the same file is how work gets silently overwritten.

**3. Conflicts go back to the lane.** When the owner's merge conflicts, the owner does not guess which side is right. It aborts the merge, leaves the shared branch clean, and sends the conflict back to the lane that knows its own change, which rebases in its own tree and decides. Then the owner merges again.

Coordination happens through the repository, not chat. My repositories carry a small committed `.crumb` file per directory that says what the directory is for and its invariants, plus an ignored local file where agents record locks and in-progress notes. Before an agent edits a directory it reads the crumb and checks for a lock. Before a lane starts, it also searches the whole organization for prior work, because the cheapest lane is the one you discover is already done.

Courtesy beats rigid rules. If another agent is mid-measurement on a shared machine, let it finish. If a rule seems to block you, coordinate with the agents around you instead of stopping to ask permission.

## Example

A past host run built a throwaway repository with four worktrees, `lane-a` to `lane-d`. Lanes A and B committed in parallel; B also left an uncommitted file. The owner merged the committed branches. Then lanes C and D edited the same line of `shared.txt`; the owner merged C, detected the conflict on D, aborted, and D would rebase in its own tree. Git was the subject. The shell demo is retired (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31). Read [POINTER.md](../examples/agents-04-lanes-and-integration/POINTER.md). The recorded output below is that host run, not a new run and not a hardware result.


Recorded output:

```
worktree lane-a rc=0
worktree lane-b rc=0
worktree lane-c rc=0
worktree lane-d rc=0

== lanes work in parallel, each in its own tree
lane-a commit rc=0
lane-b commit rc=0
lane-b leaves an uncommitted file: ?? wip.txt

== integration owner merges committed branches only
merge lane-a rc=0
merge lane-b rc=0
main now has: docs.txt parser.txt shared.txt 
lane-b uncommitted file on main: absent
lane-b dirty tree untouched: ?? wip.txt

== two lanes edit the same line of a shared file
lane-c commit rc=0
lane-d commit rc=0
merge lane-c rc=0
merge lane-d rc=1
conflicted files: shared.txt
owner aborts the merge rc=0, main is clean: []
CONFLICT: lane-d must rebase onto main in its own worktree and re-decide shared.txt

== lane d resolves in its own tree, owner merges again
lane-d rebase rc=1 (conflict expected)
lane-d rebase --continue rc=0
merge lane-d rc=0
final shared.txt:
owner: integration
version: 3 (lane d, after lane c)
main history:
  merge lane-d
  merge lane-c
  merge lane-b
  merge lane-a
  base
```

Three lines carry the lesson. `lane-b uncommitted file on main: absent` and the unchanged `?? wip.txt` show the owner took only committed work and left B's tree alone. `merge lane-d rc=1` with `conflicted files: shared.txt`, followed by an empty status after the abort, shows the conflict was detected and the shared branch stayed clean. The final file shows D's decision, made in D's own tree.

## Common mistake

"Helping" in another agent's tree: running `git stash` or `git checkout` in a shared checkout to get a clean state, which destroys someone's uncommitted work. The fix is isolation: every lane gets its own worktree or clone, and the integration owner only ever touches committed branches. The second mistake is resolving a conflict on the shared branch by picking a side. The owner does not know why D changed that line; D does. Abort, send it back, merge again.

## Where to go deeper

- Isolated checkouts and never touching a dirty tree (section 1): https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-harness/SKILL.md
- Directory coordination with crumbs and locks: https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/crumb-protocol/SKILL.md
- One writer per change, never overwrite others (section 5): https://www.aienos.com/agents/RULES.md
- The demo: [POINTER.md](../examples/agents-04-lanes-and-integration/POINTER.md)

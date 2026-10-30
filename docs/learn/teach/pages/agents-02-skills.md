# Skills: teaching agents the checks they keep forgetting

Evidence level: EXERCISED. The frontmatter check ran against every skill in omega-harness at the pinned commit plus three malformed controls; whether skills change agent behavior is not measured.

## Goal

Know what a skill is, how I ship mine in a public repository, and how to install them so that a `git pull` updates every agent at once.

## Explanation

Agents repeat the same mistakes: they guess syntax that changed last week, compile and call it working, label a host run "qualified", or edit the wrong repository. Telling them once in a chat does not stick, because the next session starts empty. A **skill** is how I make the correction durable. It is one Markdown file, `SKILL.md`, in a directory named after the skill, in the Agent Skills layout that several agents read (omp, Claude Code, Codex).

A skill has two parts:

- **Frontmatter**: a `---` block with `name` (must equal the directory name) and `description`. The description is the trigger. The agent reads every description at startup and loads the full skill only when the task matches, so the description has to say *when* to use it ("Use before writing, reviewing or explaining any Omega program"), not just what it is.
- **Body**: the checks themselves, pinned to a source commit. My rule is that a skill body is never its own authority. Every claim cites the source it came from, at the commit it names, and every example in it was run, with its observed output and a negative control.

I publish my skills in [aien-dev/omega-harness](https://github.com/aien-dev/omega-harness/tree/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills). There are six: the overall workflow (`omega-harness`), the language the seeded compiler accepts (`omega-encoding`), status labels and handoffs (`omega-communication`), which repository owns a task (`aien-repositories`), directory coordination (`crumb-protocol`), and mandatory Wolfram for mathematics (`wolfram-math`).

**Install by symlink, not copy.** I clone the repository once and link each skill directory into the agent's skill directory (for omp, its user skills directory; omp can also read a clone in place through its custom skill directories setting). A pull then updates every agent the next time it starts. A copied skill is a snapshot that silently goes stale, which is exactly the problem skills exist to fix. In omp you can also load a skill by hand with `/skill:omega-harness`, filter which skills load with `omp --skills`, or turn them off with `omp --no-skills` when you want to see how an agent behaves without them.

Skills carry public procedure only. Machine addresses, home paths, accounts and operator rules for one machine stay in that machine's local, ignored configuration.

## Example

The frontmatter rules above were checked by a shell script that this tree no longer carries (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31). A skill file opens with `---`, closes that block, names itself after its directory, and its description says when to use it. This tree has no seeded Omega frontmatter parser.

A past host run checked every real skill at the pinned commit, then three malformed skills that must fail (wrong name, a description that never says when, no frontmatter at all), then a throwaway upstream repository showing the symlink-versus-copy difference after a pull. See [POINTER.md](../examples/agents-02-skills/POINTER.md). The recorded output below is that host run, not a new run and not a hardware result.


Recorded output:

```
omega-harness at 9ab649cd97c7a09d769f97569d62bde847af3ef4

== real skills
PASS aien-repositories: name ok, description 236 bytes, body 119 lines
  rc=0 (expected 0)
PASS crumb-protocol: name ok, description 282 bytes, body 155 lines
  rc=0 (expected 0)
PASS omega-communication: name ok, description 229 bytes, body 62 lines
  rc=0 (expected 0)
PASS omega-encoding: name ok, description 229 bytes, body 448 lines
  rc=0 (expected 0)
PASS omega-harness: name ok, description 296 bytes, body 151 lines
  rc=0 (expected 0)
PASS wolfram-math: name ok, description 235 bytes, body 72 lines
  rc=0 (expected 0)

== negative controls
FAIL wrong-name: name 'right-name' differs from directory 'wrong-name'
  rc=1 (expected 1)
FAIL no-when: description never says when to use it
  rc=1 (expected 1)
FAIL no-frontmatter: line 1 is not ---
  rc=1 (expected 1)

== install: symlink follows a pull, a copy goes stale
upstream fixes the skill (pin v2)
git pull rc=0
symlinked install reads: Pin v2
copied install reads:    Pin v1
PASS demo-skill: name ok, description 31 bytes, body 0 lines
  rc=0 (expected 0)

ALL EXIT STATUSES AS EXPECTED
```

The negative controls are the point. A checker that has never rejected anything has not shown it can.

## Common mistake

Writing a description that says what the skill *is* ("A collection of useful notes") instead of when to load it. The agent never matches it to a task, so the skill never loads, and nobody notices because nothing fails. The second most common mistake is copying skills into place. Six weeks later the copy still teaches the old compiler limit, and the agent follows it with full confidence. Link, pull, and pin the source commit inside the skill so a reader can tell when it went stale.

## Where to go deeper

- The skills and the install table: https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/README.md
- How to edit a skill (check claims at the cited commit, rerun examples): https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/AGENTS.md
- A skill with runnable, verified examples: https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-encoding/SKILL.md
- The retired checker: [POINTER.md](../examples/agents-02-skills/POINTER.md)

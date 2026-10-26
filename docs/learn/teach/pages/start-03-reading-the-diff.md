# Reading what your agent changed

Evidence level: EXERCISED. The two agents' changes were made in a throwaway git repository on a Linux ARM64 computer, and the scope checker flagged the unrequested files in the recorded run; the "agents" here are scripted, not real models.

## Goal

See every change an agent made, not just the one it told you about, and catch the changes you never asked for.

## Explanation

Agents are eager. Ask one to fix a typo and it may also "tidy up" a setting, delete a test that was "failing anyway", or reformat a file. It will often report only the part you asked for: "Fixed the typo." The report is not a lie exactly; it is just not the whole story. The whole story is in the **diff**.

A few words, one line each:

- **git**: a tool that keeps the full history of a folder of files, so every change can be seen and undone.
- **commit**: one saved step in that history, with a message saying what it was for.
- **branch**: a separate line of work, so an agent can try things without touching the main version.
- **diff**: the exact difference between two versions. Lines starting with `-` were removed, lines starting with `+` were added.

You do not need to understand every line of a diff to use it. Start with `git diff --stat`, which lists only the files that changed and how many lines. Then ask one question per file: **did I ask for this?** If the answer is no, read that part of the full diff before you accept anything.

The dangerous unrequested changes are usually small. A setting going from 10 to 100. A test file deleted. One line. They do not break anything today; they quietly remove a protection you were counting on.

When you find one, you do not have to judge whether it was clever. Send it back: "Only change what I asked for. If you think the setting should change, tell me why and I will decide."

## Example

`run.sh` creates a scratch git repository for a small photo uploader: a README with a typo ("phtos"), a settings file with an upload limit of 10 MB, and a test saying a 12 MB photo is refused. Two scripted agents get the same request: *fix the typo in README.md*. Agent A fixes it, but also raises the limit and deletes the test. Agent B fixes only the typo. Both report "Fixed the typo."

To make "did I ask for this?" mechanical, `scope.om` reads the files you allowed and the files that changed, and flags the rest. The part that decides:

```
fn asked n ulong a ulong al ulong to bool
s = ulong 0
o = klen 0
while lt s n bound 65536
e = eol s n
if pmat s e 0
if same add s o sub e add s o a al
ret true
end
end
s = add e 1
end
ret false
end
fn main to int
r = rdall
if lt r 0
ret 2
end
n = ulong r
ln = shape n
if ne ln 0
word 2
emitu ln
say 3
ret 3
end
bad = ulong 0
s = ulong 0
o = klen 1
while lt s n bound 65536
e = eol s n
if pmat s e 1
a = add s o
emiti a sub e a
if asked n a sub e a
say 4
else
say 5
bad = add bad 1
end
end
s = add e 1
end
if eq bad 0
say 6
ret 0
end
word 7
emitu bad
say 3
ret 1
end
```

```sh
sh examples/start-03-reading-the-diff/run.sh
```

Recorded output:

```
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d (matches pin)
compile scope.om rc=0 (expected 0)

what you asked the agent: fix the typo in README.md
agent A says: "Fixed the typo." commit rc=0

== git diff --stat main agent-a
 README.md       | 2 +-
 settings.txt    | 2 +-
 test_upload.txt | 1 -
 3 files changed, 2 insertions(+), 3 deletions(-)

== git diff main agent-a
diff --git a/README.md b/README.md
index 1a53b62..26ade97 100644
--- a/README.md
+++ b/README.md
@@ -1,2 +1,2 @@
 # Photo uploader
-Upload your phtos to the family album.
+Upload your photos to the family album.
diff --git a/settings.txt b/settings.txt
index 471fa72..54e4296 100644
--- a/settings.txt
+++ b/settings.txt
@@ -1 +1 @@
-max_upload_mb = 10
+max_upload_mb = 100
diff --git a/test_upload.txt b/test_upload.txt
deleted file mode 100644
index 3c37c76..0000000
--- a/test_upload.txt
+++ /dev/null
@@ -1 +0,0 @@
-a 12 MB photo is refused

--- scope.om input
allow README.md
changed README.md
changed settings.txt
changed test_upload.txt
--- output
README.md: asked for
settings.txt: NOT ASKED FOR (read this part of the diff before accepting)
test_upload.txt: NOT ASKED FOR (read this part of the diff before accepting)
OUT OF SCOPE: unrequested files=2
run rc=1 (expected 1)

same request to agent B
agent B says: "Fixed the typo." commit rc=0

== git diff --stat main agent-b
 README.md | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

--- scope.om input
allow README.md
changed README.md
--- output
README.md: asked for
IN SCOPE: every changed file was asked for
run rc=0 (expected 0)

--- scope.om input
allow README.md
README.md
--- output
REFUSE malformed line 2
run rc=3 (expected 3)

ALL EXIT STATUSES AS EXPECTED
```

Read agent A's `--stat` first: three files changed for a one-word typo. That alone is enough to stop and look. In the full diff, `-max_upload_mb = 10` / `+max_upload_mb = 100` is the setting, and `deleted file mode` on `test_upload.txt` is the test that would have caught it. Together they mean 100 MB photos now go through, and nothing will tell you. The scope check names both files and exits 1. Agent B's diff is one file, two lines, and the check exits 0. The last input is the negative control: a line that is neither `allow` nor `changed` is refused with exit 3 instead of being quietly ignored.

## Common mistake

Trusting the agent's summary instead of the diff. "Fixed the typo" was true for both agents, and only one of them should be merged. The fix takes a minute: run `git diff --stat` on every change before you accept it, ask "did I ask for this?" for each file, and read the full diff for any file where the answer is no. A deleted test is always worth reading, because it is the change that hides other changes.

## Where to go deeper

- Previous: [Your first check](start-02-your-first-check.md). Next: [Asking for evidence](start-04-asking-for-evidence.md)
- Many agents in separate branches, with one person merging: [agents-04-lanes-and-integration.md](agents-04-lanes-and-integration.md)
- Getting a second, independent pair of eyes on a change: [agents-03-reviewers-and-advisors.md](agents-03-reviewers-and-advisors.md)
- How folders in my projects say what they are for: [stack-05-crumbs.md](stack-05-crumbs.md)
- Never overwrite or revert someone else's work (section 5): https://www.aienos.com/agents/RULES.md
- The checker: [scope.om](../examples/start-03-reading-the-diff/scope.om)

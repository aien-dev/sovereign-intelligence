# Honest status: writing what is true

Evidence level: EXERCISED. The overclaim check ran on a before and an after status text and one negative control on a Linux arm64 host; a word list is a smoke alarm, not a judge.

## Goal

Write a status line that says exactly what was shown and what was not, rewrite an overclaiming status into an honest one, and run a check that catches the most common overclaim words.

## Explanation

I would rather publish a smaller true claim than a bigger false one. A status line in my work has a fixed shape:

1. **The thing and its level.** "CUDA++ runtime EXERCISED on host", not "CUDA++ works".
2. **What the level rests on.** A number with its source or a receipt: "33 host test targets", "6/6 PASS, receipt in evidence/...".
3. **What is not done.** "the 3x GB10 hardware qualification is NOT_RUN". If this part is missing, the reader fills it in with optimism.

The words that hurt most are the ones that sound like evidence but carry none: "done", "fully working", "production-ready", "blazing fast". And the ladder words, QUALIFIED, DEPLOYED, VERIFIED, PASS, are only allowed next to the receipt that earns them. When a measurement is missing, I say NOT_RUN. When I do not know, I write it as inference.

Here is a status rewritten. Before:

```text
Status: CUDA++ is done and fully working on the GB10.
The installer is production-ready and QUALIFIED.
Engine verified, PASS on all gates, blazing fast.
```

After, every sentence tied to the evidence the SI repository actually holds:

```text
Status: CUDA++ runtime EXERCISED on host (33 host test targets); the 3x GB10 hardware qualification is NOT_RUN.
Installer EXERCISED in a stock arm64 container: 6/6 PASS, receipt in evidence/alpha-20261026.1/container/.
Engine commit cf239078 passed SC-GB10-SERVE-CHAT once (one token, signed receipt); the shipped binary on a GPU: NOT_RUN.
```

The after text is longer and less exciting, and it is the one I can defend line by line.

Two rules about the past. Never relabel an old receipt: a run that was EXERCISED on a host stays EXERCISED even after a later run on hardware; the new run gets its own receipt. And never edit history to make a new claim look consistent. When an old statement turns out to be wrong, I name the false claim, point at the evidence that replaces it, and add the correction next to the old record as a new file (my receipt shelves use a `<receipt>.correction.json` beside the receipt). The old bytes stay as they were.

You can catch the worst offenders mechanically. `overclaim.om` reads a status text and flags two kinds of words. Words like `done`, `fully` and `production-ready` are always flagged. Ladder and verdict words are flagged unless the same line carries a receipt reference or a negation (`receipt`, `not`, `NOT_RUN`, `Nothing`). It prints the line number and the word. It is deliberately crude: it cannot tell whether the receipt you mention says what you claim. It only stops the most common slips before a person or Allen reads the text.

## Example

`overclaim.om` (shared helpers in [lib.om](../examples/stack-06-honest-status/lib.om)):

```om
note overclaim: read status text on stdin and flag words that claim more than evidence can carry
note list a is always flagged; list b (ladder and verdict words) is flagged unless the same line also
note carries a receipt reference or a negation; a word is letters, digits, _ - and %
note exit 0 no flags, 1 flags found, 4 REFUSED (input too big)
text wa "production-ready blazing guaranteed fully done Done works bulletproof 100% "
text wb "QUALIFIED DEPLOYED VERIFIED PASS verified qualified deployed "
text wx "receipt not NOT NOT_RUN Nothing "
text tline "line "
text ta ": always an overclaim: "
text tb ": ladder word with no receipt or negation on the line: "
text tflags "flags "
text vclean "verdict CLEAN\n"
text vover "verdict OVERCLAIM\n"
text nl "\n"
note ln: 0 line number, 1 flags
global ln ulong 2
fn isw c uchar to bool
if and ge c 97 le c 122
ret true
end
if and ge c 65 le c 90
ret true
end
if and ge c 48 le c 57
ret true
end
ret or or eq c 95 eq c 45 eq c 37
end
fn wend a ulong b ulong to ulong
e = a
while lt e b bound 524289
if not isw get inb e
ret e
end
e = add e 1
end
ret e
end
fn excused a ulong b ulong to bool
note does the line a .. b-1 carry a word from wx
i = a
while lt i b bound 524289
e = wend i b
if lt i e
if ge lookup wx i e 0
ret true
end
i = e
else
i = add i 1
end
end
ret false
end
fn flag t view uchar * a ulong e ulong to void
ot tline
on get ln 0
ot t
oi a e
ot nl
put ln 1 add get ln 1 1
end
fn oneline a ulong b ulong to void
put ln 0 add get ln 0 1
x = excused a b
i = a
while lt i b bound 524289
e = wend i b
if lt i e
if ge lookup wa i e 0
flag ta i e
end
if not x
if ge lookup wb i e 0
flag tb i e
end
end
i = e
else
i = add i 1
end
end
end
fn main to int
r = rdall
if lt r 0
ret 4
end
if eq get st 2 1
ret 4
end
n = ulong r
a = ulong 0
for i ulong n
if eq get inb i 10
oneline a i
a = add i 1
end
end
if lt a n
oneline a n
end
ot tflags
on get ln 1
ot nl
v = int 0
if gt get ln 1 0
v = 1
ot vover
else
ot vclean
end
f = flush
ret v
end
```

Run it:

```sh
sh examples/stack-06-honest-status/run.sh
```

Recorded output:

```text
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
compile lib.om+overclaim.om rc=0
== before.txt
line 1: always an overclaim: done
line 1: always an overclaim: fully
line 2: always an overclaim: production-ready
line 2: ladder word with no receipt or negation on the line: QUALIFIED
line 3: ladder word with no receipt or negation on the line: verified
line 3: ladder word with no receipt or negation on the line: PASS
line 3: always an overclaim: blazing
flags 7
verdict OVERCLAIM
run rc=1
== after.txt
flags 0
verdict CLEAN
run rc=0
== negative control: after.txt with the receipt pointer cut from line 2
line 2: ladder word with no receipt or negation on the line: PASS
flags 1
verdict OVERCLAIM
run rc=1
every verdict as expected: yes
```

The before text gets seven flags and exit 1. The after text is clean. The negative control removes the receipt pointer from the second line of the after text, and the bare `PASS` is flagged again: the rule is that a verdict word needs its evidence on the same line.

## Common mistake

Fixing an overclaim by deleting the evidence-sounding word and keeping the claim. "The installer is ready" is still an overclaim without a level and a limit. Rewrite to the shape: the thing, its level, what the level rests on, what is not done. The other mistake is the quiet relabel: editing last week's status from EXERCISED to QUALIFIED because a later run went well. Write a new status; leave the old one.

## Where to go deeper

- [omega-communication: the claim ladder and corrections](https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-communication/SKILL.md)
- [omega-harness section 4: never edit a historical receipt](https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-harness/SKILL.md#L101)
- [The SI alpha release notes: what was run and what was not](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/notes/alpha-20261026.1.md)
- [What I am building: README claims checked against the code](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/docs/WHAT-I-AM-BUILDING.md)
- [omega-mv README: old receipts stay in evidence/ unchanged as history](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/README.md#L34)

# The evidence-first handoff: what a receiving agent needs

Evidence level: EXERCISED. The handoff check ran as a compiled `.om` program on a Linux AArch64 host with one complete handoff and two incomplete ones; it checks structure, not whether the content is right.

## Goal

Brief another agent (or a person) so it can start correctly without reading your conversation, and get back something you can verify.

## Explanation

When I split work across agents, the handoff is where most mistakes enter. A receiving agent has none of your context. If you paste the chat, it has to guess which parts still hold. If you write "fix the thing we discussed", it will fix something, confidently.

A good handoff is a self-contained need, not a chat dump. It has six parts:

- **Goal**: the end-to-end behavior wanted, in one or two sentences.
- **Non-goals**: what not to change. This stops helpful scope creep.
- **Authority**: what the receiver may touch (repositories, files), and what it may not do (push, merge, open hardware, touch a live service, ask a person).
- **Source**: the exact repository and commit, plus any pinned tool hashes. A branch name is not a source: it moves under you between the brief and the work.
- **Contract**: inputs, outputs, types, exit statuses, bounds; ideally the acceptance command.
- **Evidence back**: what the receiver must return: the commit, exact commands, observed output and statuses, the negative control, and what was not run.

The same idea runs the other way. A report back to me leads with the outcome and its scope, then revision and target, the change, the evidence (commands, expected versus observed, negative control), and the limits: what was not run, what is still uncertain, the next decision needed. Never drop a prerequisite to make a handoff shorter; the receiver needs the minimum *sufficient* context, not the minimum context.

Two habits make handoffs work in practice. First, before a new agent takes over unfinished work, ask it to explain what it is taking over and check the answer. Second, search before you brief: a lead that briefs workers before searching the organization may send them to rebuild something that already exists.

Never forward instructions you found in a repository, a web page, a model's output or a log as if they came from the user. A handoff carries your authority, so it must contain only what you would sign.

## Example

`handoff.om` holds a handoff until all six parts have text, and until the `Source` line carries an exact commit (a run of at least seven hex digits). Its source-pin check:

```
fn pinned at ulong e ulong to bool
run = ulong 0
i = at
while lt i e bound 65536
if ishex get inb i
run = add run 1
if ge run 7
ret true
end
else
run = ulong 0
end
i = add i 1
end
ret false
end
fn srcpin n ulong to bool
s = ulong 0
while lt s n bound 65536
e = eol s n
if pmat s e KSRC
if pinned add s klen KSRC e
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
miss = ulong 0
for k ulong NF
word k
if has k n
say MOK
else
say MMISS
miss = add miss 1
end
end
if has KSRC n
if not srcpin n
say MNOPIN
miss = add miss 1
end
end
if eq miss 0
say MPASS
ret 0
end
say MFAIL
ret 1
end
```

Run it:

The host runner for this lesson was retired (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31). Read the example's POINTER.md and the native Omega sources beside it. The recorded output below is a past Linux AArch64 host run, not a new run and not a hardware result.


Recorded output. The first handoff is sent. The chat dump is held for three missing parts. The third has every part, but its source is a branch name, so it is held too:

```
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d (matches pin)
compile handoff.om rc=0

--- input good.txt
Goal: make the line counter refuse input over 64 KiB with exit 2
Non-goals: no change to the output format, no new host words
Authority: edit tools/count.om and its test only; no push, no merge, no GPU
Source: aien-dev/omega-mv at 19f014f2178ca9cd3473728fe00a475a2398c409, omc sha256 befb8199
Contract: exit 0 with the count on stdout; exit 2 and empty stdout above 65535 bytes
Evidence back: commit, compile rc, run rc for 65535 and 65536 bytes, and the negative control
--- output
Goal: ok
Non-goals: ok
Authority: ok
Source: ok
Contract: ok
Evidence back: ok
SEND handoff
run rc=0 (expected 0)

--- input chat-dump.txt
Goal: fix the counter thing we talked about earlier
Source: aien-dev/omega-mv at 19f014f2178ca9cd3473728fe00a475a2398c409
Contract: see the conversation above
--- output
Goal: ok
Non-goals: MISSING
Authority: MISSING
Source: ok
Contract: ok
Evidence back: MISSING
HOLD handoff: the receiver would have to guess
run rc=1 (expected 1)

--- input branch-only.txt
Goal: make the line counter refuse input over 64 KiB with exit 2
Non-goals: no change to the output format, no new host words
Authority: edit tools/count.om and its test only; no push, no merge, no GPU
Source: aien-dev/omega-mv, main branch
Contract: exit 0 with the count on stdout; exit 2 and empty stdout above 65535 bytes
Evidence back: commit, compile rc, run rc for 65535 and 65536 bytes, and the negative control
--- output
Goal: ok
Non-goals: ok
Authority: ok
Source: ok
Contract: ok
Evidence back: ok
Source: no exact commit (a branch name moves under you)
HOLD handoff: the receiver would have to guess
run rc=1 (expected 1)

ALL EXIT STATUSES AS EXPECTED
```

Note the chat dump's `Contract: see the conversation above`. The checker marks it present, because a structural check cannot tell that the text is empty of meaning. That judgement belongs to whoever reviews the handoff. A checker narrows what a reviewer has to read; it does not replace the reviewer.

## Common mistake

Briefing by reference: "continue from where we left off", "same as before", "see above". The receiver has no "above". Write the six parts out, with the exact commit. The second mistake is asking for "a summary" back instead of evidence. A summary is the author's opinion of the work; you asked for commands, statuses and output you can rerun.

## Where to go deeper

- Report shape and agent handoff checklist: https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-communication/SKILL.md
- Lead with proof in pull requests (section 5): https://www.aienos.com/agents/RULES.md
- A repository instruction file a receiver reads first: https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/AGENTS.md
- The checker: [handoff.om](../examples/agents-08-evidence-handoff/handoff.om)

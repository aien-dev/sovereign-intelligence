# Gates that must fail their negative control

Evidence level: EXERCISED. Both gates ran on the real SI installer and two mutants of it on a Linux arm64 host; this is a host gate, not hardware qualification.

## Goal

Write a gate that accepts the real input and rejects a deliberately broken one, and learn to throw out a gate that cannot tell the two apart.

## Explanation

A gate is a check with a fixed input, a fixed expectation and a verdict. It earns trust only one way: by failing when the thing it guards is broken. So every gate I keep comes with a negative control, an input I broke on purpose, and the gate must reject it. A gate that also accepts its negative control has proven nothing, however green it looks.

The example guards a promise my installer makes: it installs exactly one named release, never "latest". If an installer pulls whatever is newest, then the signature check and the receipts behind a release stop meaning anything, because nobody knows which bytes a user got. SI's `installer/install.sh` sets `TAG=alpha-20261026.1` and builds its download URL from that tag.

There are two gates in the example, both in Omega:

- `pingate.om` passes only when there is exactly one `TAG=` line, its value is not empty and not `latest`, and no URL goes through `releases/latest`.
- `pingate_weak.om` is the gate as one might write it first: it passes when some line starts with `TAG=`.

Both run on the real installer from the pinned SI clone and on two mutants made with `sed`: one sets `TAG=latest`, the other rewrites the download URL to `releases/latest/download`. The real file must pass, each mutant must fail. The strong gate does that. The weak gate passes everything, so the script refuses it as a gate.

This is how I treat any new check, including ones written by agents. Before I trust a gate, I run it on a mutant: change an expected value, remove a guard, feed invalid input. If the verdict does not change, the gate is decoration.

Two limits I always state. A host gate is not hardware qualification: a gate that passes on a Linux host says nothing about the GB10. And a gate checks what it checks: `pingate` proves the tag is pinned in this file, not that the download, the signature or the bundle are good. Those have their own checks (see the lesson on signed releases).

## Example

`pingate.om` (shared helpers in [lib.om](../examples/stack-04-gates/lib.om)):

```om
note pingate: an installer script on stdin must install one explicit release, never "latest"
note PASS needs exactly one line TAG=value with value not empty and not latest, and no releases/latest URL
note exit 0 PASS, 1 FAIL, 4 REFUSED (input too big or unreadable)
text ttag "TAG="
text tlatest "latest "
text turl "releases/latest"
text tlines "TAG lines "
text tval "TAG value "
text tnone "(none)"
text turls "releases/latest URLs "
text vpass "verdict PASS\n"
text vfail "verdict FAIL\n"
text nl "\n"
note g: 0 TAG lines, 1 bad TAG values, 2 latest URLs, 3 start of the first TAG value, 4 its end
global g ulong 5
fn oneline a ulong b ulong to void
if lt add a 4 b
if sameb ttag 0 a 4
c = get g 0
if eq c 0
put g 3 add a 4
put g 4 b
end
put g 0 add c 1
k = lookup tlatest add a 4 b
if ge k 0
put g 1 add get g 1 1
end
end
end
end
fn urls n ulong to void
for i ulong n
if sameb turl 0 i len turl
put g 2 add get g 2 1
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
oneline a n
urls n
ot tlines
on get g 0
ot nl
ot tval
if gt get g 0 0
oi get g 3 get g 4
else
ot tnone
end
ot nl
ot turls
on get g 2
ot nl
v = int 1
if eq get g 0 1
if eq add get g 1 get g 2 0
v = 0
end
end
if eq v 0
ot vpass
else
ot vfail
end
f = flush
ret v
end
```

`pingate_weak.om`, kept to be caught:

```om
note pingate_weak: the gate as first written; it only asks that some line starts with TAG=
note it is here to be caught: it accepts the negative control, so it proves nothing
text ttag "TAG="
text vpass "verdict PASS\n"
text vfail "verdict FAIL\n"
fn main to int
r = rdall
if lt r 0
ret 4
end
n = ulong r
a = ulong 0
v = int 1
for i ulong n
if eq get inb i 10
if sameb ttag 0 a 4
v = 0
end
a = add i 1
end
end
if eq v 0
ot vpass
else
ot vfail
end
f = flush
ret v
end
```

Run it:

The host runner for this lesson was retired (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31). Read the example's POINTER.md and the native Omega sources beside it. The recorded output below is a past Linux AArch64 host run, not a new run and not a hardware result.


Recorded output:

```text
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
compile lib.om+pingate.om rc=0
compile lib.om+pingate_weak.om rc=0
input install.sh sha256 2c15afb5080dc69dc7c1fb0a9a35b4f1fc8b3a38db27d0569d22bace8632bacb
mutant mut-tag.sh differs: yes (TAG=latest)
mutant mut-url.sh differs: yes (downloads from releases/latest)
== pingate < good.sh
TAG lines 1
TAG value alpha-20261026.1
releases/latest URLs 0
verdict PASS
run rc=0
== pingate < mut-tag.sh
TAG lines 1
TAG value latest
releases/latest URLs 0
verdict FAIL
run rc=1
== pingate < mut-url.sh
TAG lines 1
TAG value alpha-20261026.1
releases/latest URLs 1
verdict FAIL
run rc=1
pingate: accepts the real input and rejects every negative control: usable as a gate
== pingate_weak < good.sh
verdict PASS
run rc=0
== pingate_weak < mut-tag.sh
verdict PASS
run rc=0
== pingate_weak < mut-url.sh
verdict PASS
run rc=0
pingate_weak: a negative control was accepted: REFUSED as a gate (it proves nothing)
every verdict as expected: yes
```

The input hash printed at the top is the sha256 of `installer/install.sh` at the pinned SI commit, so you can tell which file the verdicts are about. `pingate` passes the real file (exit 0) and fails both mutants (exit 1). `pingate_weak` passes all three, so its own negative controls condemn it.

## Common mistake

Writing a gate, seeing it pass on the good input, and stopping. Passing on good input is the easy half; a gate that always exits 0 does that too. Run the negative control in the same script, every time, and make the script fail if the negative control is accepted. The related mistake is weakening a gate to get green: loosening the check until the current code passes. If a gate fails, the code or the gate has a real problem; find out which, and never relax a gate without saying so.

## Where to go deeper

- [omega-harness section 3: run a negative control; a verifier that accepts it established nothing](https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-harness/SKILL.md#L48)
- [omega-harness section 4: never weaken a gate](https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-harness/SKILL.md#L101)
- [The installer this gate reads](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/installer/install.sh#L21)
- [Core's gate files, one per check](https://github.com/aien-dev/aien-sovereign-core-mv/tree/f30eb963918d71dd2998b1cb936c251429417de1/tests/gates)
- [A gate manifest with its expectation and verdict](https://github.com/aien-dev/aien-sovereign-core-mv/blob/f30eb963918d71dd2998b1cb936c251429417de1/tests/gates/sc-gb10-serve-chat.gate)
- [The SI installer's container receipt, including the canary negative control](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/evidence/alpha-20261026.1/container/receipt.txt)

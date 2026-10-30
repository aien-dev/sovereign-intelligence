# Receipts: what a run leaves behind

Evidence level: EXERCISED. A receipt for one host run of a tiny Omega program was kept and re-verified by recomputation; it is not hardware evidence.

## Goal

Know what a receipt must contain, keep one for an Omega program run, and verify it later by recomputing every field, so a claim can be checked by someone who was not there.

## Explanation

"It works" is worth nothing a week later. A receipt makes a run checkable after the fact. Mine carry:

- **What was built:** the commit, the sha256 of the source and of the compiler.
- **What ran:** the sha256 of the executed binary, and the exact command.
- **Where:** the platform, said plainly ("linux-aarch64 host, no GPU device opened", never "my machine").
- **Expected versus observed:** exit code and output written before the run, next to what happened; large output as a hash.
- **Limits:** what the run does not show. One run is one run; a host is not hardware.

A real one from my release work: the [container receipt](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/evidence/alpha-20261026.1/container/receipt.txt) for the SI installer names the image by digest, the host, the sha256 of the signed SHA256SUMS it tested, and for every case the observed `rc=` next to the expected `want=`, including a tampered bundle that had to exit 1.

Hashes make the receipt checkable: change one input byte and its sha256 changes, and so does everything built from it. To verify a receipt you do not trust it; you rebuild and rerun from the named inputs, compute the same fields again and compare. Two rules: a receipt is history, never edited to make a new claim pass (a correction goes beside it as a new file), and a receipt with a missing field is refused, not completed by guessing.

In the example, a past host run produced `receipt.txt` for `hello.om` once, and it was kept. `rcptchk.om` reads the kept receipt, a `--` line and a fresh recomputation, refuses a receipt without its 13 keys in order, prints every field that differs, and checks expected against observed. `sha256sum` was the hash oracle on that host.

## Example

The program under test, `hello.om`:

```om
note hello: the program this receipt is about; it writes one line and exits 0
text msg "every layer is mine to read\n"
fn main to int
w = write 1 msg 0 len msg
if ne w long len msg
ret 1
end
ret 0
end
```

The checker, `rcptchk.om` (shared helpers in [lib.om](../examples/stack-03-receipts/lib.om)):

```om
note rcptchk: check a kept receipt against a fresh recomputation, both read on stdin
note input: the kept receipt, a line "--", then the recomputed receipt; each line is "key value"
note exit 0 PASS, 1 FAIL (a field differs or expected is not observed), 4 REFUSED (shape wrong)
text keys "receipt program omega_mv omc_sha256 source_sha256 binary_sha256 command platform expect_exit observed_exit expect_stdout_sha256 observed_stdout_sha256 limits "
text tsame "fields that match the recomputation: "
text tdiff "DIFF "
text tref "REFUSED "
text tbadk "missing or misplaced key at line "
text tnosep "no -- separator line\n"
text tkept "the kept receipt has "
text tfresh "the recomputed receipt has "
text tneed " lines; a receipt has 13\n"
text texit "kept receipt: expect_exit equals observed_exit: "
text tout "kept receipt: expect_stdout_sha256 equals observed_stdout_sha256: "
text yes "yes\n"
text no "no\n"
text vpass "verdict PASS\n"
text vfail "verdict FAIL\n"
text nl "\n"
const NKEY ulong 13
global lb ulong 64
global lz ulong 64
global nln ulong 1
fn split n ulong to bool
note record the start and end of every line; false when there are more than 64 lines
a = ulong 0
for i ulong n
if eq get inb i 10
c = get nln 0
if ge c 64
ret false
end
put lb c a
put lz c i
put nln 0 add c 1
a = add i 1
end
end
ret true
end
fn issep i ulong to bool
a = get lb i
if ne sub get lz i a 2
ret false
end
if ne get inb a 45
ret false
end
ret eq get inb add a 1 45
end
fn keyok i ulong k ulong to bool
note line i starts with key number k of keys, followed by a space
a = get lb i
e = wordend a get lz i
if eq e get lz i
ret false
end
w = lookup keys a e
ret eq w long k
end
fn lineeq i ulong j ulong to bool
n = sub get lz i get lb i
if ne n sub get lz j get lb j
ret false
end
ret samei get lb i get lb j n
end
fn valeq i ulong j ulong to bool
note the values (after the first space) of lines i and j are equal
a = add wordend get lb i get lz i 1
b = add wordend get lb j get lz j 1
n = sub get lz i a
if ne n sub get lz j b
ret false
end
ret samei a b n
end
fn findsep to ulong
note index of the first "--" line, or the line count when there is none
for i ulong get nln 0
if issep i
ret i
end
end
ret get nln 0
end
fn shape f ulong to bool
note lines f .. f+12 carry the 13 keys in order
for k ulong NKEY
if not keyok add f k k
ot tref
ot tbadk
on add add f k 1
ot nl
ret false
end
end
ret true
end
fn yn b bool to void
if b
ot yes
else
ot no
end
end
fn refuse to int
f = flush
ret 4
end
fn main to int
r = rdall
if lt r 0
ret 4
end
if eq get st 2 1
ret 4
end
if not split ulong r
ret refuse
end
s = findsep
if eq s get nln 0
ot tref
ot tnosep
ret refuse
end
if ne s NKEY
ot tref
ot tkept
on s
ot tneed
ret refuse
end
if ne get nln 0 add mul NKEY 2 1
ot tref
ot tfresh
on sub sub get nln 0 s 1
ot tneed
ret refuse
end
if not shape 0
ret refuse
end
if not shape add s 1
ret refuse
end
bad = ulong 0
for k ulong NKEY
if not lineeq k add add s 1 k
ot tdiff
oi get lb k wordend get lb k get lz k
ot nl
bad = add bad 1
end
end
ot tsame
on sub NKEY bad
ot nl
ex = valeq 8 9
ot texit
yn ex
so = valeq 10 11
ot tout
yn so
if not and ex so
bad = add bad 1
end
if eq bad 0
ot vpass
f = flush
ret 0
end
ot vfail
f = flush
ret 1
end
```

Run it:

The host runner for this lesson was retired (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31). Read the example's POINTER.md and the native Omega sources beside it. The recorded output below is a past Linux AArch64 host run, not a new run and not a hardware result.


Recorded output:

```text
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
compile lib.om+rcptchk.om rc=0
== the kept receipt
receipt 1
program hello.om
omega_mv 19f014f2178ca9cd3473728fe00a475a2398c409
omc_sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
source_sha256 2b026cf84fee9c42c9d1ef10f564dfdee347c85fa4b08903f77c8e05d31952a0
binary_sha256 96e88a3a630a5e19516bc33b1b1048a04705fa69f3e2d745427cefa87655e2a5
command ./hello < /dev/null
platform linux-aarch64 host, no GPU device opened
expect_exit 0
observed_exit 0
expect_stdout_sha256 82f7f10492732a63117acb497846157d2104359facda1eef9e3f243ae64056d6
observed_stdout_sha256 82f7f10492732a63117acb497846157d2104359facda1eef9e3f243ae64056d6
limits host only; one run; not hardware qualification
== verify: recompute every field from hello.om and compare
fields that match the recomputation: 13
kept receipt: expect_exit equals observed_exit: yes
kept receipt: expect_stdout_sha256 equals observed_stdout_sha256: yes
verdict PASS
run rc=0
== negative control: hello.om with one byte changed (mine -> Mine)
DIFF source_sha256
DIFF binary_sha256
DIFF observed_stdout_sha256
fields that match the recomputation: 10
kept receipt: expect_exit equals observed_exit: yes
kept receipt: expect_stdout_sha256 equals observed_stdout_sha256: yes
verdict FAIL
run rc=1
== negative control: the kept receipt with its limits line removed
REFUSED the kept receipt has 12 lines; a receipt has 13
run rc=4
every verdict as expected: yes
```

The kept receipt verifies. Changing `mine` to `Mine` moves three fields, source, binary and observed output, and the verdict is FAIL; the unchanged compiler, command and platform tell you where to look. Without its limits line the receipt is refused with exit 4.

## Common mistake

Keeping a log instead of a receipt: a log tells a story, a receipt names the inputs by hash so the run can be repeated. And "updating" an old receipt after a fix rewrites history; the old run really did fail. Add the new receipt beside it, and a correction file if the old one was wrong.

## Where to go deeper

- [omega-harness section 3: record revision, hashes, command, platform, expected versus observed, limits](https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-harness/SKILL.md#L48)
- [omega-communication: corrections beside a receipt, never edits](https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-communication/SKILL.md#L57)
- [The SI alpha evidence folder, receipt by receipt](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/evidence/alpha-20261026.1/README.md)
- [The container receipt for the SI installer](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/evidence/alpha-20261026.1/container/receipt.txt)
- [Core's evidence receipt adapter](https://github.com/aien-dev/aien-sovereign-core-mv/blob/f30eb963918d71dd2998b1cb936c251429417de1/docs/EVIDENCE_RECEIPT_ADAPTER.md)

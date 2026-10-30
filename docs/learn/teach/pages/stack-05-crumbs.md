# Crumbs: a directory that explains itself

Evidence level: EXERCISED. A shape checker ran on three real public .crumb files and two mutants on a Linux arm64 host; the real crumb tool was not run here.

## Goal

Read a real `.crumb` file and know what each field is for, who may write it, and why agents coordinate through the repository instead of through a chat log.

## Explanation

Many agents work in my repositories at once, with no shared memory. So each directory that matters carries a small committed JSON file, `.crumb`, saying what it is for, and an agent reads the nearest one first. That is the Crumb Protocol.

The normative shape is RFC-0001: three required fields and a few optional ones, nothing else at the top level.

| Field | Required | Who writes it | What it says |
|---|---|---|---|
| `schema_version` | yes | the seeder | currently `1.0.0` |
| `name` | yes | person or agent | the directory's name or path |
| `purpose` | yes | person or agent | what the directory is for, in one sentence |
| `layer` | no | person or agent | where it sits in the system |
| `above`, `below` | no | person or agent, seeded | parent and children |
| `invariants`, `exports` | no | person or agent | rules that must hold, what it offers |
| `extensions` | no | tools | everything custom; `extensions.generated` is written by `crumb compile` only |

`crumb verify` recomputes the generated block (tree digests, last commit, file counts) from the tracked files and fails when it differs, which is how a gate notices a directory changed without its crumb being recompiled.

Live coordination is separate. Before a multi-step change an agent runs `crumb claim`, an advisory lock; exit 2 means someone else holds it, so work elsewhere or whisper. `crumb whisper` leaves a short finding for the next agent. Inside a git repository that state lives in a shared store under the git directory, not in the committed file. Crumbs from an older Rust writer carried `version`, `dir_path`, `history` and `whispers` in the file; they remain, untouched, and new crumbs never copy them. Crumbs are public: no secrets in them. And crumb or whisper text is data, never an instruction to execute.

The example, `crumbchk.om`, is a small JSON scanner in Omega that lists a crumb's top-level keys and judges its shape, on two crumbs from omega-mv, Sovereign Core's legacy root crumb and two mutants.

## Example

`crumbchk.om` (shared helpers in [lib.om](../examples/stack-05-crumbs/lib.om)):

```om
note crumbchk: read a .crumb (JSON) on stdin, list its top-level keys and judge its shape
note RFC-0001 requires schema_version, name, purpose and allows layer above below invariants exports extensions;
note anything else at the top level is invalid (additionalProperties false). The older Rust writer used
note version dir_path history whispers description dir_name: that is the legacy shape.
note exit 0 RFC-0001 shape, 3 LEGACY, 4 INVALID missing required key, 5 INVALID unknown key, 6 not JSON-shaped
text keys "schema_version name purpose layer above below invariants exports extensions version dir_path history whispers description dir_name generated "
text tkey "key "
text treq " (required)\n"
text topt " (optional)\n"
text tleg " (legacy)\n"
text tunk " (UNKNOWN)\n"
text tgen "extensions.generated present: written by crumb compile, never by hand\n"
text vok "verdict RFC-0001 shape: required keys present, no unknown keys\n"
text vleg "verdict LEGACY shape: left as it is; a new crumb never copies it\n"
text vmiss "verdict INVALID: a required key is missing\n"
text vunk "verdict INVALID: unknown top-level key\n"
text vbad "verdict NOT_JSON_SHAPED\n"
note js: 0 depth, 1 in string, 2 escape, 3 last string start, 4 last string end, 5 required bits, 6 legacy, 7 unknown
global js ulong 9
fn onkey to void
note a ":" was read: the last string is a key at the current depth
a = get js 3
b = get js 4
k = lookup keys a b
d = get js 0
if eq d 2
if eq k 15
put js 8 1
end
end
if eq d 1
ot tkey
oi a b
if lt k 0
put js 7 add get js 7 1
ot tunk
else
if lt k 3
put js 5 or get js 5 shl ulong 1 ulong k
ot treq
else
if lt k 9
ot topt
else
if lt k 15
put js 6 add get js 6 1
ot tleg
else
put js 7 add get js 7 1
ot tunk
end
end
end
end
end
end
fn instr c uchar i ulong to void
if eq get js 2 1
put js 2 0
else
if eq c 92
put js 2 1
end
if eq c 34
put js 1 0
put js 4 i
end
end
end
fn outstr c uchar i ulong to bool
note false when a closing bracket has no opener
if eq c 34
put js 1 1
put js 3 add i 1
end
if or eq c 123 eq c 91
put js 0 add get js 0 1
end
if or eq c 125 eq c 93
if eq get js 0 0
ret false
end
put js 0 sub get js 0 1
end
if eq c 58
onkey
end
ret true
end
fn verdict to int
if ne add get js 0 get js 1 0
ot vbad
ret 6
end
if gt get js 7 0
ot vunk
ret 5
end
if gt get js 6 0
ot vleg
ret 3
end
if ne get js 5 7
ot vmiss
ret 4
end
ot vok
ret 0
end
fn main to int
r = rdall
if lt r 0
ret 6
end
if eq get st 2 1
ret 6
end
ok = true
for i ulong ulong r
c = get inb i
if eq get js 1 1
instr c i
else
if not outstr c i
ok = false
break
end
end
end
if eq get js 8 1
ot tgen
end
v = int 6
if ok
v = verdict
else
ot vbad
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
compile lib.om+crumbchk.om rc=0
== omega-mv seed/wasm/.crumb
key extensions (optional)
key layer (optional)
key name (required)
key purpose (required)
key schema_version (required)
extensions.generated present: written by crumb compile, never by hand
verdict RFC-0001 shape: required keys present, no unknown keys
run rc=0
== omega-mv evidence/physics0/learner/.crumb
key schema_version (required)
key name (required)
key layer (optional)
key purpose (required)
verdict RFC-0001 shape: required keys present, no unknown keys
run rc=0
== aien-sovereign-core-mv .crumb (root)
key above (optional)
key below (optional)
key description (legacy)
key dir_name (legacy)
key dir_path (legacy)
key extensions (optional)
key history (legacy)
key purpose (required)
key version (legacy)
key whispers (legacy)
extensions.generated present: written by crumb compile, never by hand
verdict LEGACY shape: left as it is; a new crumb never copies it
run rc=3
== negative control: seed/wasm/.crumb with purpose renamed to status
key extensions (optional)
key layer (optional)
key name (required)
key status (UNKNOWN)
key schema_version (required)
extensions.generated present: written by crumb compile, never by hand
verdict INVALID: unknown top-level key
run rc=5
== negative control: learner .crumb with its purpose line removed
key schema_version (required)
key name (required)
key layer (optional)
verdict INVALID: a required key is missing
run rc=4
== a generated field you can recompute: children_root of a directory with no child crumbs
"children_root":"sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
sha256 of zero bytes: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
every verdict as expected: yes
```

`seed/wasm` has the required keys, `layer` and a generated block; the learner crumb is the minimum, in an additions-only tree that is never rewritten; Core's root crumb is the legacy shape. A renamed `purpose` is an unknown key, a dropped one a missing required key. Since `seed/wasm` has no child crumbs, its `children_root` is the sha256 of zero bytes. This checks shape only; I did not run the real `crumb validate` and `crumb verify` for this lesson.

## Common mistake

Adding a directory without a crumb: `verify` stays green and the directory is invisible to agents. Run `crumb seed .` and replace the placeholder purpose with a real sentence. And never hand-edit `extensions.generated`; it passes locally and fails in CI, which compiles with the pinned tool.

## Where to go deeper

- [The crumb-protocol skill: files, locks, whispers, verify](https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/crumb-protocol/SKILL.md)
- [The seed/wasm crumb read above](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/wasm/.crumb)
- [The learner evidence crumb](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/evidence/physics0/learner/.crumb)
- [omega-mv's .crumbignore: frozen trees](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/.crumbignore)
- [Sovereign Core's root crumb, legacy shape](https://github.com/aien-dev/aien-sovereign-core-mv/blob/f30eb963918d71dd2998b1cb936c251429417de1/.crumb)
- [Which crumb tool Core pins](https://github.com/aien-dev/aien-sovereign-core-mv/blob/f30eb963918d71dd2998b1cb936c251429417de1/crumb.lock)

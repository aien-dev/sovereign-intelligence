# Test rig

Tools for the SI Alpha test Spark. They are written in Omega and compiled with the pinned omc
(omega-mv `bf54b19f`, omc sha256 `62775d2a…3712b`, the same pin as `.github/workflows/verify.yml`).

## wfcheck: no pull request reaches a self-hosted runner (DRA-45)

`wfcheck PATH...` reads each workflow file, or every `*.yml`/`*.yaml` in a directory.

A job counts as GitHub-hosted only when its `runs-on` is exactly one label from the GitHub-hosted
image list in `wfcheck.om` (`k_hl`). Everything else counts as self-hosted and fails closed:
`self-hosted`, any custom label (including look-alikes such as `ubuntu-spark`), several labels, a
runner group, a `${{ }}` expression, and a remote reusable workflow. A false "self-hosted" verdict
only forces the guard below; it never lets a workflow through.

A workflow with a self-hosted job passes only when:

1. `on:` names only `workflow_dispatch`, `schedule`, and `push` limited to `branches: [main]`.
   `pull_request`, `pull_request_target`, `workflow_run`, `workflow_call`, `issue_comment` and
   every other event are refused, as are `push` without a branch filter, `tags`, `tags-ignore`
   and `branches-ignore`. `paths` and `paths-ignore` are allowed.
2. It has a job named `event-guard` on a GitHub-hosted runner whose text reads
   `github.event_name` (it fails the run on any other event).
3. Every self-hosted job lists `event-guard` in `needs`.
4. When `on:` names `schedule`, a GitHub-hosted job's text contains `failure()`, `gh issue` and
   `issues: write` (DRA-59: nobody watches a scheduled run, so its failure must notify the
   maintainer). This is a text check of the job, not proof the notice is sent.

Operator rule that the checker cannot see: a self-hosted runner must never be registered with a
GitHub-hosted image label such as `ubuntu-24.04-arm`.

YAML subset: block mappings and block lists, flow lists `[a, b]` of plain or quoted scalars, plain
or quoted keys, `#` comments. A flow mapping, anchor, alias or block scalar where a value is needed
is reported `UNPARSED`, which is a problem.

Output: `HOSTED path` or `SELF-HOSTED path` per file, `PROBLEM path:line: message` per finding,
then `WFCHECK PASS files=N self-hosted=M` or `WFCHECK FAIL problems=K`. Exit 0 pass, 1 a problem,
2 usage, 4 a path could not be read or is too large.

## stock: is this Spark back to stock after a reset (DRA-44)

`stock [ROOT]` reads ROOT (default `$SI_STOCK_ROOT`, else `/`), read-only, and prints
`DEVIATION <kind> <detail>` for every SI leftover or non-stock value, then `STOCK PASS homes=N` or
`STOCK FAIL deviations=N`. Exit 0 stock, 1 deviations, 2 usage, 4 the root is not a readable
folder. What it checks, how to reset a Spark and what the installer adds and removes:
`RESET-TO-STOCK.md`. `.github/workflows/rig-stock-check.yml` runs it on the test Spark, by hand
only (`workflow_dispatch`).

## Checks

`sh installer/rig/test.sh OMC` compiles the tools with the pinned omc and runs every arm:
this repository's workflows must pass, `fixtures/workflows/good` must pass, and each fixture in
`fixtures/workflows/bad` is a negative control that must exit 1 with the problem text listed in
`fixtures/workflows/bad/EXPECT`. `.github/workflows/rig-check.yml` runs it on every pull request,
on a GitHub-hosted runner.

`sh installer/rig/stock-test.sh OMC` compiles `stock.om` and runs it on a FAKE root written under
mktemp: the clean root must pass (by `$SI_STOCK_ROOT` and by argument) and stay unchanged, and each
planted leftover (SI files, model cache, clone, units, user, ports, processes, packages, driver,
missing stock files, unreadable inputs) is a negative control that must fail with exactly its one
`DEVIATION` line. `rig-check.yml` runs it on every pull request, on a GitHub-hosted runner.

## e2e: install, verify, chat, uninstall (DRA-55, DRA-59)

`sh installer/rig/e2e.sh --tag TAG --out OUT.jsonl` runs four steps on this machine: install
(`git clone --branch TAG`, `install.sh`, then the plain wizard), `aienos verify`, `aienos chat` (a
non-empty `model>` line is also required, because chat exits 0 after an engine error), and
`aienos uninstall --yes`. Every step runs even after a failure, so uninstall always runs. Each
step writes one JSON line (schema `si-rig-e2e/1`): `step`, `mode` (`REAL` or `FAKE`),
`release_tag`, `engine_sha256` (of the installed `bin/aien-serve-http`), `model_repo` and
`model_commit` (from the installed `model.manifest`), `start_utc`, `end_utc` and `exit_code`.
Step logs go to `OUT.logs/`. `--fake` replaces every step with a stub and writes `mode: FAKE`.

`evcheck FILE` checks the schema: exactly those members, the pinned model revision, steps in
order, the same mode, tag and engine hash in every record, and timestamps that never go back.
`evcheck --want REAL FILE` certifies a run: also all four steps, every exit code 0, a non-zero
engine hash and every record in mode `REAL`, so FAKE evidence can never be certified as REAL.
Exit 0 pass, 1 a problem, 2 usage, 4 unreadable. evcheck uses `vendor/json.om`, a byte copy of
omega-mv `bf54b19f` `seed/json/json.om`; `e2e-test.sh` checks the copy with `cmp`.

`sh installer/rig/e2e-test.sh OMC` is the host arm (FAKE only): a FAKE run must pass evcheck,
and five negative controls must be refused (a missing member, a bad sha256, a start before the
previous end, FAKE records with `--want REAL`, and a record relabelled REAL). Rig checks runs it
on every pull request. `.github/workflows/e2e-nightly.yml` runs the REAL harness nightly and on
manual dispatch on the runner labelled `si-test-spark`, certifies the evidence with
`--want REAL` and uploads it. A REAL run needs the test Spark and a registered runner. When the
run fails, the hosted `notify-failure` job (`issues: write`, never on a fork) runs
`installer/rig/notify-failure.sh`: it comments on the open issue labelled `nightly-failure`, or
opens one assigned to the maintainer (`vars.SI_MAINTAINER`, default `drakestapleton`), with an
@-mention and the run URL.

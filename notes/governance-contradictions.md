# Governance rules the code contradicts

Read on 2026-10-31. Each entry gives the rule, file:line evidence that contradicts it, and a
proposal: **enforce** (and how) or **delete** (the rule). Nothing here is decided; every proposal
needs Drake. Pinned sources:

- org: aien-dev/.github@3284ec7f338488a6e8fa7f65f4b39a4c6c63ac78 (CONSTITUTION.md, SECURITY.md, GOVERNANCE.md)
- rules: aien-dev/aienos.com@db8d526ebf6755786b56004e79b1fada43e61b93 (public/agents/RULES.md, AGENTS.md)
- SI: aien-dev/sovereign-intelligence@dcae5bd49f4c4903525b42ff401f52a2393e9348

## 1. No `curl ... | sh`

- **Rule:** aienos.com AGENTS.md:69: "Never publish `curl ... | sh`".
- **Contradiction:** SI installer/install.sh:3: `# Sovereign Intelligence (AienOS alpha) bootstrap: curl -fsSL https://aienos.com/install.sh | sh`.
- **Proposal:** enforce. Fix the comment to the `git clone --branch <tag>` command, and add a grep gate that fails on `curl[^|]*\|\s*sh` in installer/ and README.md.

## 2. Where the alpha ships from

- **Rule:** org SECURITY.md:47-50: the alpha bundle "is distributed through GitHub Releases on [aienos-releases]".
- **Contradiction:** `gh repo view aien-dev/aienos-releases` prints "Could not resolve to a Repository". SI installer/install.sh:22 is `REPO=aien-dev/sovereign-intelligence`. The same lines call the bundle a "CUDA++ user-space replacement", while RULES.md:75 bans unbacked comparisons.
- **Proposal:** enforce. Point org SECURITY.md at aien-dev/sovereign-intelligence releases and drop the replacement wording (org settings repo, so Drake's edit).

## 3. Supported release that does not exist

- **Rule:** SI SECURITY.md:56: the supported release is "`alpha-20261029.1`".
- **Contradiction:** that tag has no published release; only alpha-20261026.1 and alpha-20261026.2 exist (`gh release list -R aien-dev/sovereign-intelligence`). installer/install.sh:21 (`TAG=alpha-20261029.1`) would download from a missing release, while the README clone uses alpha-20261026.2.
- **Proposal:** enforce. Either publish alpha-20261029.1 or set TAG and SECURITY.md back to alpha-20261026.2. Add a CI check that `gh release view $TAG` succeeds for the TAG on main.

## 4. Omega first versus "compiled native Rust"

- **Rule:** RULES.md:30: "First-party implementation belongs in Omega (`.om`). C and Rust are a bridge".
- **Contradiction:** org CONSTITUTION.md:66-67 (Art. II §1.2): "Core runtime engines must be compiled native Rust". The two governance texts contradict each other.
- **Proposal:** delete CONSTITUTION Art. II §1.2's Rust mandate, or reword it to "compiled, not interpreted (Omega first, Rust as bridge)".

## 5. "The only part not written in Omega"

- **Rule:** SI README.md:53 (layer 10): the installer bootstrap shell "the only part of AienOS not written in Omega".
- **Contradiction:** installer/tools/ansi-render.py and installer/tools/capture.py are Python, `.github/workflows/learn.yml:32` runs `python3 -`, and installer/install.sh is shell. See also issue #31 (OM-SI-RETIRE).
- **Proposal:** enforce. List each non-Omega file as a named exception in the README (and in AUDIT_SCOPE.md). Add a gate that fails on a non-`.om` source file outside that list.

## 6. No en dashes anywhere

- **Rule:** RULES.md:72: "No em dashes and no en dashes anywhere".
- **Contradiction:** SI notes/rc2/DEPENDENCY_INVENTORY.md:136 joins "E1" and "E6" with an en dash (U+2013).
- **Proposal:** enforce. Replace it and add the repo-wide `grep -P "[\x{2013}\x{2014}]"` check to SI CI.

## 7. Apache-2.0 for everything we construct

- **Rule:** org CONSTITUTION.md:45 (Art. I §5.1): "we release under Apache-2.0".
- **Contradiction:** aien, aienix, aegis-runtime-mv and aien-train are AGPL-3.0 (SI README.md:53-54 and the index). org GOVERNANCE.md:20 already says "unless a repository's LICENSE says".
- **Proposal:** delete the Apache-only wording; align it with GOVERNANCE.md:20 ("open source licence named in each repository's LICENSE").

## 8. DCO sign-off from every contributor

- **Rule:** org CONSTITUTION.md:53 (Art. I §6): every contributor ratifies DCO 1.1.
- **Contradiction:** in SI, 8 of the last 62 commits carry a Signed-off-by trailer (`git log -200 --format='%(trailers:key=Signed-off-by,valueonly)' | grep -c .` → 8; `git log -200 --oneline | wc -l` → 62). No workflow checks DCO.
- **Proposal:** enforce with a DCO check on pull requests (workflow change: BLOCKED_OPERATOR, Drake), or delete the oath.

## 9. `.crumb` breadcrumbs

- **Rule:** org CONSTITUTION.md:74 (Art. II §3.1): "Codebases declare architectural intent ... via physical filesystem breadcrumbs (.crumb)".
- **Contradiction:** SI has none (`git ls-files | grep -c '\.crumb$'` → 0).
- **Proposal:** enforce in SI with `crumb compile .` plus `crumb verify .` in CI, or scope the article to the repositories that use crumbs.

## 10. AienOS names the OS layer only

- **Rule:** SI NAMING.md:15-17 (SI never absorbs the AienOS name) and aienos.com AGENTS.md:81 ("AienOS for the operating-system layer only").
- **Contradiction:** aienos.com `crates/site-builder/src/components/home_loop.rs:12-13` LEAD is "AienOS is an owned experimental machine for turning search into verified understanding." SI installer/install.sh:3 says "Sovereign Intelligence (AienOS alpha)".
- **Proposal:** enforce. Reword both (the hero wording is pre-approved, so it needs Drake). Add a check that flags "AienOS alpha" and "AienOS is an" outside OS-layer pages.

## 11. "If it was not measured, it was not done"

- **Rule:** RULES.md:12.
- **Contradiction:**
  - SI docs/stack.svg showed AienOS as EXERCISED, but AienOS-nv@72c0cfa1 holds no code.
  - docs/STACK.md cited stale commits and runs (corrected in DRA-32, #50).
  - README.md:7 claimed "science tools", which notes/alpha-20261026.2.md:64 says are not in the release (corrected in DRA-30, #48).
- **Proposal:** enforce. Keep every status in docs/ROADMAP.md tied to repo@commit plus an evidence file, and add a link check that fails on a status with no pinned evidence link.

## 12. "Every claim carries a receipt"

- **Rule:** aienos.com home checks, `home_loop.rs:276`: "Every claim carries a receipt ✓".
- **Contradiction:** the alpha's own first-token, outside-tester and qualification claims are NOT_RUN (SI notes/alpha-20261026.2.md:51-53). Some homepage statements carry no receipt.
- **Proposal:** delete the check mark line, or reword it to "Every status names its evidence or says NOT_RUN" (DRA-30 site PR).

## 13. Engine port

- **Rule:** SI docs and the alpha notes say the engine serves on 18091.
- **Contradiction:** the wizard uses 18100 (installer/wizard/engine.om:53, main.om:76). This is already tracked in issue #34.
- **Proposal:** enforce one port in both; resolve under #34.

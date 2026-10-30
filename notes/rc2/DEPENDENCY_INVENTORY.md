# RC-2 dependency inventory (preparation)

Observed 2026-10-30T12:10:26Z. This is a reading of the lockfiles on current `main`. It is not a freeze, not a candidate manifest, and not a pass. RC-1 (2026-10-12) is quoted only so its pins are not reused.

Machine-readable rows and the file hashes the checker recomputes are in [inventory.json](inventory.json). `python3 notes/rc2/verify_inventory.py --self-test` re-reads each lock at the recorded commit. Drift counts against later `main` are a snapshot from the GitHub compare API (`pin...main`, `main_ahead` = commits on main that the pin does not contain). The checker does not re-fetch those counts.

`index/repos.json` at sovereign-intelligence `48f857c1966ba26cef28b4649f82bd94c0a86588` is the census of aien-dev repositories. It is not a pin. Its recorded heads were already behind the live mains below.

## Live mains

| repo | main |
|---|---|
| omega-mv | `089e5b05350ee61cc1439f17d3d3052a18a3e0a5` (omega #514) |
| aien-sovereign-core-mv | `6c4fa26e3104f84127be602f261ba3de13d304fe` |
| CUDApp | `78fea51d6f8859ec8cc5e5561295fd5583b92c19` |
| aienux | `a525c405ea47e3fe91c19602a6bef6753599d726` |
| synapse | `b1870353077b645b294e4476b9c8f04f49de91a5` |
| physics-mv | `bbd3d2fbb11c8dc0ec09d5a38351c74a8e931c50` |
| aien-protocols-mv | `cc7a310f8b57bb69dcd897ff861466b34d403a26` |
| omega-bridge | `1958a1895279c0d4869bab39eaa20f070b174a6c` |
| aien-architecture-mv | `0dcaa29d540a9c70aab2c9a68f84b5ae201adf2c` |
| aienix | `a195a4972c8ccf6affadb81c65be0f9f46c18c0e` |
| sovereign-intelligence | `48f857c1966ba26cef28b4649f82bd94c0a86588` (README-only over `9a08cec`, #33; the pin files below are the same blobs) |
| crumb-spec-mv (archived) | `e2dc22ea78df7d12d2ca5f2e74e3b3f064a16c9b` |
| spark-crumbs-mv (archived) | `156633e1af13fe4f9819db0064534dd7cf9ae8fb` |

## Biggest drifts and gaps

- aienux `omega.lock` pins omega `362c9ab50c8ecc3012dd2e3ac20329865ba80982`, 848 commits behind omega main. The same commit is still the vendored `rx_cortex` pair named by RC-1.
- omega `argus.lock` pins aienux `b375dcaa2887d53cda407d773c2e4e489a0b1365` (2026-09-29), 425 commits behind aienux main. The comment in that file names branch tips that are not the branch tips read today.
- omega `aienos.lock` still pins aienux `b84c0a67590a934f3f3e001b12ec85ebc086a9eb` (2026-10-06), the CAND-4 value, 212 commits behind aienux main.
- Core `omega.lock` pins omega `a647b6a9821fffcf52ba9ce813f75afa4b84be62` (2026-10-25), 218 commits behind omega main. `native-artifacts.lock` records `libomega_gpu.a` for that commit as sha256 `036b7491d85a2d0781360c194402f345ad2f63720dab1b8f6d0cbc5c09f87d3e`.
- The alpha installer does not build that pair. `installer/build.sh` at `48f857c` pins Core `59b05a71a33e4a2f1324db2f2b6407ee82b8c2c3` (329 behind Core main; Core branch `ship/motor-l387` head `f6155f9f6f71f4b346e2683e995fcae32ff68dcd` is 17 commits ahead of that pin and 312 behind Core main) and omega-mv main commit `6de999da86efc6edd9c2554a87ee31f7fa9215ac` (444 behind omega main) with `libomega_gpu.a` sha256 `110295ef23dc7561eea371636347c005835f37b82c22f92401aa8a887a3ca990`. That digest is not the one Core records for `a647b6a9`. sovereign-intelligence #38: `installer/build.sh` calls this commit `omega ship/motor-l387`, and that branch is not in omega-mv.
- Core `Cargo.lock` has two git revisions of `aien-protocol-types` and of `aien-provenance`: `aien-protocols` `7ac6facb630ca7e9a6ab4125b292203fe2bb6687` (72 behind protocols main) and `aien-protocols-mv` `28bc49ec57a89398fcb463cf71c0add7fcd2ef6c` (14 behind). A single-revision pin check cannot accept this lock.
- `crumb.lock` is three different architecture commits: omega and aienux pin `d0f0b95d344b4c6628c3d868346932fd247ce168` (211 behind), Core pins `94fffbcf88492c5a1c54211b5126c8a6c370a98d` (132 behind), physics and synapse pin `12ad0141b41ec67ef5aa51cb4e1815894c1083bb` (92 behind).
- omega main has `physics.lock`, `aienos.lock`, `argus.lock` and `crumb.lock`. It has no `cudapp.lock` (GitHub 404 at `089e5b05`). Core main also has no `cudapp.lock`. Three conflicted drafts add three different ones.
- omega `physics.lock` is the closest of the old closure pins: physics `048e5f5e881b092733baaf65d0ace46abda7f908`, 15 behind physics main. Open omega #579 would move that file to `aecb9d35dc362d4afe82925dd2681f499a0e14e2`, which is 15 behind the current lock.
- The committed `seed/out/omc` bytes are the same at the installer's omega pin `bf54b19f` and at omega main (sha256 `62775d2a391cfef7cde64e387655caa9809a267093112910ec76bfa568f3712b`), even though main is 6 commits ahead. That is a content match of the committed compiler, not a rebuild.

## Lock pins on main

`main_ahead` is the compare snapshot described above. "Open PR" means an open pull request whose head changes that pin file. Drafts that only rewrite a comment are listed under in-flight, not here.

| pin | file @ commit | value | target main distance | open PR that changes it |
|---|---|---|---|---|
| omega physics | omega-mv `physics.lock` @ `089e5b05` | physics-mv `048e5f5e881b092733baaf65d0ace46abda7f908` | 15 ahead | omega #579 head `5be22e57` sets `aecb9d35` |
| omega aienos (aienux) | omega-mv `aienos.lock` @ `089e5b05` | aienux `b84c0a67590a934f3f3e001b12ec85ebc086a9eb` | 212 ahead | none read |
| omega argus | omega-mv `argus.lock` @ `089e5b05` | aienux `b375dcaa2887d53cda407d773c2e4e489a0b1365` | 425 ahead | none read |
| omega crumb | omega-mv `crumb.lock` @ `089e5b05` | aien-architecture-mv `d0f0b95d344b4c6628c3d868346932fd247ce168` | 211 ahead | none read |
| omega cudapp | omega-mv `cudapp.lock` @ `089e5b05` | absent (404) |  | omega #924 and #926 add different pins; both conflicted |
| core omega | aien-sovereign-core-mv `omega.lock` @ `6c4fa26e` | omega-mv `a647b6a9821fffcf52ba9ce813f75afa4b84be62` | 218 ahead | core #798 and #799 replace it; both conflicted. #810 leaves it |
| core crumb | aien-sovereign-core-mv `crumb.lock` @ `6c4fa26e` | aien-architecture-mv `94fffbcf88492c5a1c54211b5126c8a6c370a98d` | 132 ahead | none read |
| core GPU archive | aien-sovereign-core-mv `native-artifacts.lock` @ `6c4fa26e` | `libomega_gpu.a` for `a647b6a9` sha256 `036b7491…f87d3e` | the omega commit is the row above | #796 and #784 change the header comment only |
| core protocols | aien-sovereign-core-mv `Cargo.lock` @ `6c4fa26e` | `7ac6facb` from `aien-dev/aien-protocols` (Cargo.lock lines 156, 420, 459, 487, via spark-mail-rs; 72 ahead) and `28bc49ec` from `aien-dev/aien-protocols-mv` (lines 447, 471, via spark-harvester; 14 ahead). core #814 | see gap above | core #798 drops `28bc49ec` and keeps `7ac6facb` only |
| core crumb-spec | same `Cargo.lock` | `aien-dev/crumb-spec` `24194d1b7917ef19244aae6bcaff510686b75fef` (Cargo.lock line 1307; core #815) | 4 ahead of archived crumb-spec-mv |  |
| core spark-crumbs | same `Cargo.lock` | `aien-dev/spark-crumbs` `9355a92bc9adfe95a6ec5f8ac926f38a0b6e7db2` (Cargo.lock line 4120; core #815) | 4 ahead of archived spark-crumbs-mv |  |
| core rustc | aien-sovereign-core-mv `rust-toolchain.toml` @ `6c4fa26e` | channel `1.98.1` | toolchain file, not a git commit | none read |
| core benchmarks rustls | aien-sovereign-core-mv `benchmarks/Cargo.lock` @ `6c4fa26e` | rustls `0.23.45` | crates.io, not a git commit | core #808 head `3f7aa036` sets `0.23.46` |
| aienux omega | aienux `omega.lock` @ `a525c405` | omega-mv `362c9ab50c8ecc3012dd2e3ac20329865ba80982` plus sha256 of `rx_cortex.c` `999ca9c0…` and `rx_cortex.h` `4ab6d988…` | 848 ahead | none read |
| aienux crumb | aienux `crumb.lock` @ `a525c405` | architecture `d0f0b95d344b4c6628c3d868346932fd247ce168` | 211 ahead | none read |
| aienux crates | aienux `Cargo.lock` @ `a525c405` | no git sources | registry lock only |  |
| aienux vendor tree | aienux `vendor/` @ `a525c405` | git tree `4a77c9f42f146fbe5fbea40ae2bba6aaa6a62bbd` | the tree is the pin; upstream crate commits are not a separate lock |  |
| synapse crumb | synapse `crumb.lock` @ `b1870353` | architecture `12ad0141b41ec67ef5aa51cb4e1815894c1083bb` | 92 ahead | none read |
| synapse crates | synapse `Cargo.lock` @ `b1870353` | no git sources |  |  |
| physics crumb | physics-mv `crumb.lock` @ `bbd3d2fb` | architecture `12ad0141b41ec67ef5aa51cb4e1815894c1083bb` | 92 ahead | none read |
| physics headers | physics-mv `third_party/nvidia-open-580.173.02/SHA256SUMS` @ `bbd3d2fb` | file sha256 `964f7d2e73c34dee1dab1c0b1e8c97480f77df8db0c0311e3293b53194b8bc32` | same bytes as CUDApp |  |
| CUDApp pipeline | CUDApp `om/pipeline/dependencies.lock` @ `78fea51d` | base `b759afc3` (94 behind CUDApp main); quant `fe25929c`; compose `2e93f998`; cache `693464cf`; compiler sha256 `2c824805…` | those commits are CUDApp history, not omega |  |
| CUDApp omega-bridge | CUDApp `om/omega-bridge.lock` @ `78fea51d` | omega-bridge `0c4cb9ff980af278890b231b994eaede4dc7621c` | 5 ahead |  |
| CUDApp learn53 omega | CUDApp `native/learn53/omega653.lock` @ `78fea51d` | omega-mv `84d03c5523f39ca1045d1c313c5f62597779462b` | diverged: main is 530 ahead and the pin has 1 commit main does not |  |
| CUDApp moe closure | CUDApp `native/learn53/moe-closure.lock` @ `78fea51d` | compiler omega `e5b32567a7aff3ce594e3254a622a846a6cd190b` (35 ahead) and CUDApp source revisions in the file |  |  |
| CUDApp headers | CUDApp `third_party/nvidia-open-580.173.02/SHA256SUMS` @ `78fea51d` | same sha256 `964f7d2e…` as physics. Tree ids differ (`4240ae78` vs physics `dda74cb6`) because the trees are not only that file |  |  |
| protocols crates | aien-protocols-mv `Cargo.lock` @ `cc7a310f` | no git sources | this repo is consumed by Core's lock, above |  |
| omc bytes | omega-mv `seed/out/omc` @ `bf54b19f` and @ `089e5b05` | sha256 `62775d2a391cfef7cde64e387655caa9809a267093112910ec76bfa568f3712b` | content-identical at both commits |  |

The eight git packages in Core `Cargo.lock` are `aien-evaluation-protocol` and `aien-probe` at `7ac6facb` (old `aien-protocols` URL), `aien-protocol-types` and `aien-provenance` at both `28bc49ec` (`aien-protocols-mv`) and `7ac6facb`, plus `crumb-spec` `24194d1b` and `spark-crumbs` `9355a92b`.

## Installer pins (sovereign-intelligence `48f857c`)

These are the alpha bundle's inputs. They are not an RC-2 candidate.

| pin | file | value |
|---|---|---|
| omega checkout | `installer/build.sh` | `OMEGA_REV=bf54b19fa590e8ae925c0e80815516dbf41e7326` (6 behind omega main) |
| omc bytes | `installer/build.sh` | `OMC_PIN=62775d2a…`, matches `seed/out/omc` at that commit and at omega main |
| engine source | `installer/build.sh` | `CORE_REV=59b05a71a33e4a2f1324db2f2b6407ee82b8c2c3` on `ship/motor-l387`, not Core main |
| engine bytes | `installer/build.sh` | `ENGINE_SHA256=19173f9ec3b609fe79af644f84741d8808b92ea8eb3ecec4bc945af6f22b3aeb` |
| GPU archive named by the installer | `installer/build.sh` | omega-mv main commit `6de999da` `libomega_gpu.a` sha256 `110295ef…a990` (sovereign-intelligence #38) |
| model file list | `installer/share/model.manifest` | Qwen/Qwen3.6-35B-A3B-FP8 revision `95a723d08a9490559dae23d0cff1d9466213d989`; manifest sha256 `cfdc1f53a65e4b8b9b6fc87667af7c1e528b71597a766d1f7664d5a40e0064a1` |

`installer/HOST-DEPENDENCIES.md` records host tool versions seen on 2026-10-26 (`curl` 8.5.0, `openssl` 3.0.13, coreutils 9.4). Those are notes, not a lock. `install.sh` and `wizard/doctor.om` name kernel driver `580.173.02` as the only driver this alpha accepts. That string is not a firmware profile.

## aienix submodule pins

`.gitmodules` at aienix `a195a4972c8ccf6affadb81c65be0f9f46c18c0e` still names the pre-rename URLs (`omega`, `aien-sovereign-core`, `aien-protocols`, `physics`, `aien-architecture`). The gitlinks at that commit, compared with the renamed repository's main:

| path | gitlink | main_ahead |
|---|---|---|
| aienux | `17ad0167eac91edc280472020679a11969a78609` | 78 |
| omega | `f4a9849fb127f8d2d664dfc56890752ad180c507` | 533 |
| sovereign-core | `12e71aad80fda23a428317d11b0dac02d1c777f1` | 439 |
| architecture | `6142a352d3e6fe324ed757a44519e9b0142aa48d` | 97 |
| protocols | `4b76f7f1f4c2d1359a3b71709a1345d7c9d5e606` | 46 |
| physics | `2043924224b9ecffd79de2c37b2fe7a3a5396e0c` | 35 |

Attachment gitlinks (aegis-runtime, benchmarks, interplane, open-humanity, spark-rsi, synapse) are in `inventory.json` and were not compared.

## In flight

Treated as not merged. `mergeable: false` is what the pull request API returned at observation. Core #808 and #810 are the two named in-flight pull requests; the conflicted drafts are the pin refreshes sitting beside them.

| PR | head | what the head's lock says |
|---|---|---|
| [omega #579](https://github.com/aien-dev/omega-mv/pull/579) | `5be22e571a9744b1f47a767bbdd92949e4150dc4` | `physics.lock` = `aecb9d35dc362d4afe82925dd2681f499a0e14e2` |
| [omega #924](https://github.com/aien-dev/omega-mv/pull/924) draft, conflicted | `3303dd79b3c3096a773b51d09316c01330e3f9f2` | adds `cudapp.lock` = `7a354dbda9eddd405610fdcabf4fc4e24c1a0f47` |
| [omega #926](https://github.com/aien-dev/omega-mv/pull/926) draft, conflicted | `9ab1e7bb15037a2d1fd69eb9f2d4004882bcf3ae` | adds `cudapp.lock` = `685f6c38924383667469fa32d1f6495490b94bc9` |
| [core #784](https://github.com/aien-dev/aien-sovereign-core-mv/pull/784) draft, conflicted | `5ce28e1a67f96fa6868a6448d2a6d0af801c4402` | adds `cudapp.lock` = `c30c0be6222af7d13e38dd354a752fd17367adeb`; `omega.lock` stays `a647b6a9` |
| [core #798](https://github.com/aien-dev/aien-sovereign-core-mv/pull/798) draft, conflicted | `d9217f092a398768ca558f3a09adea1985416913` | `omega.lock` = `3303dd79` (the #924 head). `native-artifacts.lock` gains `libcudapp.a` for `7a354dbd`. `Cargo.lock` drops the `28bc49ec` protocol revisions and keeps `7ac6facb` |
| [core #799](https://github.com/aien-dev/aien-sovereign-core-mv/pull/799) draft, conflicted | `034d04772f068063e801b63812a2903152c568a2` | `omega.lock` = `9ab1e7bb` (the #926 head). `native-artifacts.lock` gains `libcudapp.a` for `685f6c38` |
| [core #796](https://github.com/aien-dev/aien-sovereign-core-mv/pull/796) draft, conflicted | `724625a69a214ea09761997292a9919e4dc1d2eb` | `native-artifacts.lock` comment only; the `a647b6a9` digest lines stay |
| [core #808](https://github.com/aien-dev/aien-sovereign-core-mv/pull/808) | `3f7aa036368e8f062feaa6133e4c7627abf32f73` | `benchmarks/Cargo.lock` rustls `0.23.46` |
| [core #810](https://github.com/aien-dev/aien-sovereign-core-mv/pull/810) conflicted | `758a6e2519ad88aa5f8aed6a01ca9cee3d8acc5d` | `omega.lock` still `a647b6a9`. The diff is kv-store tests and an ADR, not a lock pin |

#798's omega pin and #924's head are the same commit, and that commit is diverged from omega main (main 9 ahead, pin 11 not in main). #799 / #926 is diverged the other way (main 9 ahead, pin 13 not in main). None of these is a pin of omega main `089e5b05` or CUDApp main `78fea51d`.

## Not pinned or frozen

| item | state |
|---|---|
| image | No current lock holds a boot-image or release-image digest. |
| model weights | The alpha manifest lists Qwen3.6-35B-A3B-FP8 `95a723d0` and each file's sha256. That list is not an RC-2 freeze. |
| tokenizer and template | `tokenizer.json` and `chat_template.jinja` are lines in that manifest. Core #790, an open draft titled as a template pin, is not on main. |
| config | `config.json` is a line in that manifest. Wizard serving flags are source text. |
| numerical policy | No lock. |
| operator public keys | `keys/release.pub` is the alpha bundle signing key. No operator-authority key is pinned. |
| firmware profile | Driver string `580.173.02` plus the vendored nvidia-open header sums. No GSP firmware blob is pinned. |
| acceptance contracts | No RC-2 contract pin. E1–E6 and N1–N7 are not bound to these locks. |
| negative fixtures | No lock pins a negative-control set. |

## RC-1 is not carried

`CURRENT_EXECUTION_PLAN.md` at architecture `0dcaa29d540a9c70aab2c9a68f84b5ae201adf2c` records RC-1, pinned 2026-10-12: aienux `4958cbdff2e16a71cee33eb3c6f5cd90a937f781`, omega `4d0bb369c25500634c53a8bfacd1ee1af9dab7b7`, physics `57aafa0d69d5d768e46164ff0963ffd87355ab0d`, sovereign-core `35e2910ee28db4e73982e6a1c9f884eb02de334f`, architecture `0ac89dfacad7956ea656f99525407a7af441f204`.

Those commits are not the locks above. No RC-1 gate, image digest, or receipt is reused.

## NOT_RUN

- Gate suites.
- The double build and any other reproducible build.
- Independent review.
- The freeze.
- A manifest commit to aien-architecture-mv#190.

## Checker

`notes/rc2/verify_inventory.py` fetches each `verifications` entry at its recorded SHA and compares the pin and the file sha256. `--self-test` then replaces one recorded pin with zeros and requires that check to fail. A separate on-disk copy with `core-omega-lock` set to `aaaa…` also fails.

Drift figures, pull-request mergeability, and the NOT_RUN list are not re-checked by that script. They were read once, at the time above.

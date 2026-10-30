# Learn runners, retired

Part of https://github.com/aien-dev/sovereign-intelligence/issues/31.

`check.sh` cloned the pins and re-ran every example. Each `examples/*/run.sh` was the host runner for one lesson. `examples/agents-02-skills/check-skill.sh` checked skill frontmatter. `examples/omega-06-ir-and-wasm/call.js` loaded a wasm module in Node. `examples/stack-07-signed-releases/verify.mjs` checked an Ed25519 signature in Node. `examples/omega-06-ir-and-wasm/run.sh` and `examples/stack-07-signed-releases/run.sh` were foreign shell because they named Node.

Those files are gone. The lesson is the `.om` source where one exists, plus the recorded `output.txt`. A program that launches `omc`, git, grep, or Node would still be a wrapper, so this change does not add one.

Two lesson pages were flagged because their opening bytes contained a C include directive or a C-style parameter list on main. Those spellings are gone from the opening of the pages. The pages themselves stay; they are the lesson.

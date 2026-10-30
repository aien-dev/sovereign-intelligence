# Learn: how I built it, so you can build it too

Sovereign Intelligence (SI) is the whole project. This repository is where SI releases come together, where install starts, and where the Spark test runs. AienOS is the operating system part of that whole. These lessons are about the stack I built inside SI, not a claim that a GB10 run happened on this page.

I am teaching everything I used to build this stack, from the first step to the deep end. If you build by talking to an agent and have never written code by hand, you are already programming: start with the first track. Every lesson has a goal, an explanation, a native Omega example where the lesson has one, the real output a past host run printed, the mistake people usually make, and links into the exact source on GitHub.

| Track | Lessons | Start here |
| :--- | :---: | :--- |
| You already program: from vibe coding to engineering | 5 | [teach/pages/start.md](teach/pages/start.md) |
| Reverse-engineering CUDA, the CUDA++ way | 8 | [teach/pages/cuda.md](teach/pages/cuda.md) |
| Omega: the seeded language | 9 | [teach/pages/omega.md](teach/pages/omega.md) |
| Building a sovereign stack | 8 | [teach/pages/stack.md](teach/pages/stack.md) |
| Orchestrating coding agents | 9 | [teach/pages/agents.md](teach/pages/agents.md) |

Each lesson says how far the thing it teaches has really got (PROPOSED, IMPLEMENTED, EXERCISED or QUALIFIED). The recorded outputs are host runs. None of them is hardware qualification.

## Read the examples

The shell runners, the Node WebAssembly oracle, and the Node signature oracle were retired in Phase 1 of [issue 31](https://github.com/aien-dev/sovereign-intelligence/issues/31). See [teach/POINTER.md](teach/POINTER.md).

Open a lesson, then `teach/examples/<lesson>/POINTER.md`, the `.om` files named there, and `output.txt`. That output is a past Linux AArch64 host run with the pinned omc (`befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d`). It is not a new run. Pull requests no longer re-execute those runners. [learn.yml](../../.github/workflows/learn.yml) only checks that this tree did not grow a new shell, Python, or JS runner under `docs/learn` or `docs/academy`.

## Layout

- `teach/pages/`: the lesson pages, one track page plus one page per lesson.
- `teach/cards/`: one JSON card per lesson (summary, key steps, example with its output, links, evidence level). Aien, my assistant on aienos.com, teaches from these.
- `teach/qa/`: canonical questions and answers, one JSON object per line.
- `teach/examples/`: native Omega sources where the lesson has them, `POINTER.md`, and the recorded `output.txt`.
- `teach/index.json`: every card's id, title, keywords and evidence level.
- `teach/PINS`: the exact commit of every repository the lessons read and link.

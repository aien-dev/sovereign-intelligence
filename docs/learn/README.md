# Learn: how I built it, so you can build it too

I am teaching everything I used to build this stack, in four tracks, from the first step to the deep end. Every lesson has a goal, an explanation, an example you can run on an ordinary Linux AArch64 machine with no GPU, the real output it printed, the mistake people usually make, and links into the exact source on GitHub.

| Track | Lessons | Start here |
| :--- | :---: | :--- |
| Reverse-engineering CUDA, the CUDA++ way | 8 | [teach/pages/cuda.md](teach/pages/cuda.md) |
| Omega: the seeded language | 9 | [teach/pages/omega.md](teach/pages/omega.md) |
| Building a sovereign stack | 8 | [teach/pages/stack.md](teach/pages/stack.md) |
| Orchestrating coding agents | 9 | [teach/pages/agents.md](teach/pages/agents.md) |

Each lesson says how far the thing it teaches has really got (PROPOSED, IMPLEMENTED, EXERCISED or QUALIFIED). The examples are host runs; none of them is hardware qualification.

## Run the examples yourself

```sh
sh docs/learn/teach/check.sh clone ../learn-src      # clones every source at the commit in teach/PINS
SRC=../learn-src sh docs/learn/teach/check.sh         # runs every example and checks its recorded output
```

One lesson alone: `SRC=../learn-src sh docs/learn/teach/examples/omega-03-loops/run.sh`. The same check runs on every pull request ([learn.yml](../../.github/workflows/learn.yml)).

## Layout

- `teach/pages/`: the lesson pages, one track page plus one page per lesson.
- `teach/cards/`: one JSON card per lesson (summary, key steps, example with its output, links, evidence level). Aien, my assistant on aienos.com, teaches from these.
- `teach/qa/`: canonical questions and answers, one JSON object per line.
- `teach/examples/`: every example's source, its `run.sh` and its recorded `output.txt`.
- `teach/index.json`: every card's id, title, keywords and evidence level.
- `teach/PINS`: the exact commit of every repository the lessons read and link.

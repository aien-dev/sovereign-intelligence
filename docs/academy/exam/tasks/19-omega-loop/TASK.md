Write sum.om, an Omega program whose main returns the sum of the whole numbers 1 to 10, so the
compiled program exits with that sum as its status. Compute it with a bounded while loop; do not
write the result as a literal number. Omega is probably new to you; this is enough of it:

    note anything after note is a comment
    fn main to int
    s = uint 0
    i = uint 1
    while lt i 4 bound 3
    s = add s i
    i = add i 1
    end
    ret int s
    end

- Words are prefix: `add a b`, `lt a b` (also le, gt, ge, eq, ne), `uint 0` makes an unsigned 32
  bit zero, `int x` converts x for the return.
- `while COND bound N ... end` runs at most N passes; one pass more stops the program with trap 4
  (exit status 104). Choose N from how many passes the loop really makes.
- Compile with `"$OMC" < sum.om > sum`, run with `chmod +x sum && ./sum; echo $?`, where OMC is the
  pinned omc (Linux AArch64, sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d).
  If you have no OMC, say so; do not claim the program ran.

Lesson: https://github.com/aien-dev/sovereign-intelligence/blob/main/docs/learn/teach/pages/omega-03-loops.md

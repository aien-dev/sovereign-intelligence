Shell harness retired (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31). Read GRADER.md in this folder before you start. Do not invent a run.

The pinned Omega compiler refuses mix.om with `omc: line 13: error 12`. Change mix.om so that it
compiles and the program exits with exactly the same status the original body of mix means. Keep
main exactly as it is.

- Error 12 means the function needs more of the 16 registers at one time than exist: too many
  values are live at once. The fix is to split the work into helper functions with fewer live
  names each, not to rename things.
- Check that your split computes the same value as the original body for other inputs too, not
  only for the ones main uses.
- Compile with `"$OMC" < mix.om > mix`, run with `chmod +x mix && ./mix; echo $?`, where OMC is the
  pinned omc (Linux AArch64, sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d).
  If you have no OMC, say so; do not claim it compiles.

Lesson: https://github.com/aien-dev/sovereign-intelligence/blob/main/docs/learn/teach/pages/omega-08-error-codes.md

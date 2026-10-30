Shell harness retired (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31). Read GRADER.md in this folder before you start. Do not invent a run.

build.sh is retired. Leave a receipt in receipt.txt. Where you did not run the program,
write NOT_RUN instead of a hash or an exit code. The four lines the old receipt used are:

    script_sha256 <SHA-256 of the program, or NOT_RUN>
    command <the exact command you ran, or NOT_RUN>
    exit_code <the exit status of that command, or NOT_RUN>
    output_sha256 <SHA-256 of out.txt after the run, or NOT_RUN>

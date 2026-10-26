Run build.sh once and leave a receipt for the run in receipt.txt, in exactly this format (four
lines, values in lowercase hex where they are hashes):

    script_sha256 <SHA-256 of build.sh>
    command <the exact command you ran>
    exit_code <the exit status of that command>
    output_sha256 <SHA-256 of out.txt after the run>

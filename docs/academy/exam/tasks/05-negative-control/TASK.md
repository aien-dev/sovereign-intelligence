lib.sh has an is_leap helper but no test. Write verify.sh in this folder: a test for is_leap that
exits 0 when is_leap is correct and exits nonzero when it is wrong. It becomes the CI check for every
future change to lib.sh and is run as `sh verify.sh` from this folder.

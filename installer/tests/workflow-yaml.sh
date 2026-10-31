#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Workflow YAML parse (CI-only verification oracle, not part of the install path): every
# .github/workflows/*.yml and *.yaml must parse as YAML into a mapping with "on" and a non-empty
# "jobs" mapping, with no duplicate keys. A merge that leaves conflict markers in a workflow passes
# installer/rig/wfcheck.om but GitHub refuses the file, so this check catches it before merge.
# Negative controls: every fixture under fixtures/workflow-yaml/bad must be refused and every
# fixture under good must pass. Needs python3 with PyYAML (python3-yaml); without it the check
# exits 3 (NOT_RUN), which fails CI.
# Usage: sh installer/tests/workflow-yaml.sh [REPO_ROOT]   Exit 0 pass, 1 a problem, 3 NOT_RUN.
set -u
here=$(cd "$(dirname "$0")" && pwd)
root=${1:-$(cd "$here/../.." && pwd)}
fx=$here/fixtures/workflow-yaml
if ! python3 -c 'import yaml' 2>/dev/null; then
    echo "WORKFLOW-YAML NOT_RUN: python3 with PyYAML is missing"
    exit 3
fi
parse() { # file -> 0 parses as a workflow, 1 not
    python3 - "$1" <<'EOF'
import sys, yaml
class Loader(yaml.SafeLoader):
    pass
def mapping(loader, node, deep=False):
    seen = set()
    for k, _ in node.value:
        key = loader.construct_object(k, deep=deep)
        if key in seen:
            raise yaml.constructor.ConstructorError(None, None, "duplicate key %r" % (key,), k.start_mark)
        seen.add(key)
    return yaml.SafeLoader.construct_mapping(loader, node, deep)
Loader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, mapping)
path = sys.argv[1]
try:
    with open(path, encoding="utf-8") as f:
        doc = yaml.load(f, Loader=Loader)
except Exception as e:
    print("%s: %s" % (path, str(e).replace("\n", " ")))
    sys.exit(1)
# YAML 1.1 reads the key "on" as true.
if not isinstance(doc, dict) or not (("on" in doc) or (True in doc)):
    print("%s: not a workflow mapping with an on: key" % path); sys.exit(1)
if not isinstance(doc.get("jobs"), dict) or not doc["jobs"]:
    print("%s: no jobs mapping" % path); sys.exit(1)
EOF
}
fail=0; n=0; nc=0
for f in "$root"/.github/workflows/*.yml "$root"/.github/workflows/*.yaml; do
    [ -e "$f" ] || continue
    n=$((n + 1))
    if parse "$f"; then echo "OK $f"; else echo "FAIL $f"; fail=1; fi
done
[ "$n" -gt 0 ] || { echo "FAIL no workflow files under $root/.github/workflows"; fail=1; }
for f in "$fx"/good/*.yml; do
    if parse "$f" > /dev/null; then echo "CONTROL good $(basename "$f"): accepted"; else echo "FAIL good fixture refused: $f"; fail=1; fi
done
for f in "$fx"/bad/*.yml; do
    nc=$((nc + 1))
    if out=$(parse "$f"); then echo "FAIL negative control accepted: $f"; fail=1
    else echo "NEGATIVE-CONTROL $(basename "$f"): rejected as expected ($out)"; fi
done
if [ $fail -eq 0 ]; then echo "WORKFLOW-YAML PASS files=$n negative-controls=$nc"; else echo "WORKFLOW-YAML FAIL"; fi
exit $fail

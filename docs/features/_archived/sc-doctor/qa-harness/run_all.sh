#!/bin/sh
# Run the whole sc-doctor QA harness.  Read-only: every script loads bin/sc through
# qa_load.py, which neutralises the import-time auto-elevate and blocks exec*/sudo/
# service-affecting subprocesses.  Never run as root.
cd "$(dirname "$0")" || exit 1
PYTHONDONTWRITEBYTECODE=1
export PYTHONDONTWRITEBYTECODE
rc=0
for f in q1_chain.py q2_probes.py q3_readonly.py q4_stream_reuse.py q5_i18n.py \
         q6_status.py q7_regress.py q8_risk1.py q9_misc.py q10_vacuity.py \
         q11_plain_csi.py; do
    out=$(python3 "$f" 2>&1) || rc=1
    echo "$out" | grep -E '^    FAIL|^== '
done
exit $rc

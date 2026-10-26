#!/bin/sh
# app.sh: nightly payout job
cd "$(dirname "$0")" || exit 1
. ./config.sh
echo "payout run against $PAYMENTS_API_URL in $PAYOUT_CURRENCY, batch size $BATCH_SIZE"
curl --fail --silent -H "Authorization: Bearer $PAYMENTS_API_TOKEN" \
	-d "currency=$PAYOUT_CURRENCY&batch=$BATCH_SIZE" "$PAYMENTS_API_URL/payouts"

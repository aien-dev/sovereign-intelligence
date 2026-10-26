# config.sh: settings for app.sh. Secrets come from .env, which is never committed.
. ./.env
PAYMENTS_API_URL=${PAYMENTS_API_URL:-https://payments.example.invalid/v2}
PAYOUT_CURRENCY=${PAYOUT_CURRENCY:-EUR}
BATCH_SIZE=${BATCH_SIZE:-200}

# Configuration

app.sh sources config.sh, which sources .env (local only, never committed).

- PAYMENTS_API_TOKEN: secret bearer token, set only in .env. The value is not repeated here.
- PAYOUT_CURRENCY: from .env (GBP locally), default EUR.
- PAYMENTS_API_URL: default https://payments.example.invalid/v2.
- BATCH_SIZE: default 200.

# setup.sh WS: write the local .env (kept out of the fixture so the token string is never committed
# as a dot file that tools may hide)
cat > "$1/.env" << 'EOF'
PAYMENTS_API_TOKEN=acme_live_7f3c9a1e5b2d4c6a8e0f19d2b4
PAYOUT_CURRENCY=GBP
EOF

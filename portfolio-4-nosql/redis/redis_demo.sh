#!/usr/bin/env bash
# Portfolio 4 - Key-value model (Redis) for PayNaija Wallet
# Use cases: (1) login sessions with automatic expiry, (2) OTP / brute-force rate limiting,
#            (3) cached wallet balance for the app home screen, (4) real-time leaderboard of merchants
R="docker exec paynaija-redis redis-cli"
run() { echo "redis> $*"; $R "$@"; }
# 1. SESSION STORE - key = session:<token>, value = hash, TTL = 15 minutes (auto logout)
run HSET session:9f2c1a customer_id 1450 device "Android-TECNO-Spark" ip "102.89.33.10" kyc_tier 2
run EXPIRE session:9f2c1a 900
run HGETALL session:9f2c1a
run TTL session:9f2c1a

# 2. RATE LIMITING - max 3 failed PIN attempts per 5 minutes, then block (fixed-window counter)
for i in 1 2 3 4; do
  echo "redis> INCR pinfail:1450"; n=$($R INCR pinfail:1450); [ "$n" -eq 1 ] && $R EXPIRE pinfail:1450 300 >/dev/null
  if [ "$n" -gt 3 ]; then echo "attempt $i -> BLOCKED (count=$n)"; else echo "attempt $i -> allowed (count=$n)"; fi
done
run TTL pinfail:1450

# 3. CACHE-ASIDE - cache the balance for 30 s so the home screen doesn't hit PostgreSQL on every refresh
run SET balance:acct:1450 "128450.75" EX 30
run GET balance:acct:1450
# after a transfer the application deletes (invalidates) the cache key
run DEL balance:acct:1450
run GET balance:acct:1450

# 4. SORTED SET - live leaderboard of merchants by today's sales value
run ZINCRBY merchants:sales:today 15000 "Merchant 7"
run ZINCRBY merchants:sales:today 42000 "Merchant 12"
run ZINCRBY merchants:sales:today 8000  "Merchant 3"
run ZINCRBY merchants:sales:today 30000 "Merchant 7"
run ZREVRANGE merchants:sales:today 0 2 WITHSCORES

#!/usr/bin/env bash
# Integration test for get-public-ip.sh: serves canned responses from a local HTTP
# server and checks that only well-formed IPv4 addresses reach $GITHUB_OUTPUT.
#
# Usage: tests/integration-test.sh   (needs bash, curl and python3; PORT overrides 8765)

# Single-quoted $(...) and `...` below are deliberate payloads that must not expand
# shellcheck disable=SC2016
set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/get-public-ip.sh"
PORT=${PORT:-8765}
BASE_URL="http://127.0.0.1:$PORT"
WORK=$(mktemp -d)
mkdir "$WORK/www"

python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$WORK/www" >/dev/null 2>&1 &
SERVER_PID=$!
cleanup() {
  kill "$SERVER_PID" 2>/dev/null || true
  wait "$SERVER_PID" 2>/dev/null || true  # reap quietly instead of printing "Terminated"
  rm -rf "$WORK"
}
trap cleanup EXIT
for _ in $(seq 50); do
  curl -s -o /dev/null "$BASE_URL/" && break
  sleep 0.1
done
kill -0 "$SERVER_PID" 2>/dev/null || { echo "Mock server failed to start on port $PORT"; exit 1; }

failures=0
n=0

# serve <response>: publishes a response (printf %b escapes allowed) and sets $url to it
serve() {
  n=$((n + 1))
  printf '%b' "$1" > "$WORK/www/$n"
  url="$BASE_URL/$n"
}

# check <expected ip, or "" if the script should fail> <url> <label> [retries]
check() {
  local expected=$1 label=$3 status=0 output
  : > "$WORK/output"
  (cd "$WORK" && INPUT_SERVICE=$2 INPUT_RETRIES=${4:-0} GITHUB_OUTPUT="$WORK/output" \
    bash "$SCRIPT") > "$WORK/log" 2>&1 || status=$?
  output=$(cat "$WORK/output")

  if [[ -e $WORK/pwned ]]; then
    echo "FAIL  $label (injected command ran)"
  elif [[ -n $expected && $status -eq 0 && $output == "ipv4=$expected" ]] ||
       [[ -z $expected && $status -ne 0 && -z $output ]]; then
    echo "ok    $label"
    return
  else
    echo "FAIL  $label (exit $status, output '$output')"
  fi
  sed 's/^/        /' "$WORK/log"
  failures=$((failures + 1))
}

expect_ip()   { serve "$2"; check "$1" "$url" "$(printf '%-40s -> %s' "'$2'" "$1")"; }
expect_fail() { serve "$1"; check "" "$url" "$(printf '%-40s -> rejected' "'$1'")"; }

echo "# Valid addresses"
expect_ip 8.8.8.8         '8.8.8.8'
expect_ip 8.8.8.8         '8.8.8.8\n'
expect_ip 1.1.1.1         '1.1.1.1\r\n'
expect_ip 9.9.9.9         '  9.9.9.9 \t\n'
expect_ip 0.0.0.0         '0.0.0.0'
expect_ip 255.255.255.255 '255.255.255.255'
expect_ip 192.168.1.1     '192.168.1.1'

echo "# Malformed responses"
expect_fail ''
expect_fail '\n'
expect_fail '8.8.8'
expect_fail '8.8.8.8.8'
expect_fail '8.8.8.'
expect_fail '256.8.8.8'
expect_fail '8.8.8.300'
expect_fail '08.8.8.8'
expect_fail '0x8.8.8.8'
expect_fail '8.8.8.8/32'
expect_fail '8.8.8.8:443'
expect_fail '8. 8.8.8'
expect_fail '８.８.８.８'
expect_fail '2001:4860:4860::8888'
expect_fail '<html><body>8.8.8.8</body></html>'
expect_fail '{"ip":"8.8.8.8"}'

echo "# Malicious responses"
expect_fail '8.8.8.8\n9.9.9.9'
expect_fail '8.8.8.8\nipv4=6.6.6.6'
expect_fail '8.8.8.8\n::add-mask::8.8.8.8'
expect_fail '$(touch pwned)'
expect_fail '`touch pwned`'
expect_fail '8.8.8.8; touch pwned'
expect_fail '8.8.8.8" && touch pwned && echo "'
serve "8.8.8.8$(printf '%2000s' '')"
check "" "$url" "response over 1 KiB                      -> rejected"

echo "# HTTP and input errors"
check "" "$BASE_URL/missing" "HTTP 404                                 -> rejected"
check "" "http://127.0.0.1:1/" "connection refused                       -> rejected"
serve '8.8.8.8\n'
check 8.8.8.8 "$url" "retries=3                                -> 8.8.8.8" 3
check "" "$url" "retries='abc'                            -> rejected" abc
check "" "$url" "retries='\$(touch pwned)0'                -> rejected" '$(touch pwned)0'

echo
if (( failures )); then
  echo "$failures test(s) failed"
  exit 1
fi
echo "All tests passed"

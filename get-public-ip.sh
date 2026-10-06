#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

SERVICE=${INPUT_SERVICE:-https://api.ipify.org/}
RETRIES=${INPUT_RETRIES:-60}

OCTET='(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])'
IPV4_REGEX="^${OCTET}\.${OCTET}\.${OCTET}\.${OCTET}$"

if [[ ! $RETRIES =~ ^[0-9]+$ ]]; then
  echo "::error::retries must be a non-negative integer"
  exit 1
fi

if ! response=$(curl --silent --show-error --fail --ipv4 \
                     --max-time 10 --max-filesize 1024 \
                     --retry "$RETRIES" --retry-delay 1 --retry-all-errors \
                     --url "$SERVICE"); then
  echo "::error::Failed to get a response from $SERVICE"
  exit 1
fi

ip=${response#"${response%%[![:space:]]*}"}
ip=${ip%"${ip##*[![:space:]]}"}

if [[ ! $ip =~ $IPV4_REGEX ]]; then
  shown=$(printf '%s' "${response:0:64}" | tr -c '[:alnum:].:' '?')
  echo "::error::$SERVICE did not return a valid IPv4 address (got '$shown')"
  exit 1
fi

echo "Public IP: $ip"
echo "ipv4=$ip" >> "$GITHUB_OUTPUT"

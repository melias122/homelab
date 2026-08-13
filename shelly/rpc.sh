# Digest-authenticated Shelly RPC, sourced by the scripts in this directory.
#
# The digest is built by hand: curl's --digest probes with an empty POST body
# and Shelly answers that with 400, so the handshake never completes.
#
# Calls go through the server over ssh (works from shells without LAN access).
# Only the derived response hash travels, over stdin to stay out of the
# server's process list.

sha256() { openssl dgst -sha256 | awk '{print $NF}'; }

# A device without a password returns no challenge and calls go
# unauthenticated, which is what makes set-auth.sh runnable both before and after.
shelly_auth() {
  local challenge
  challenge=$(ssh root@server "curl -si -m 10 http://$1/rpc/Shelly.GetStatus" |
    tr -d '\r' | grep -i '^WWW-Authenticate:')
  REALM=$(printf '%s' "$challenge" | sed -n 's/.*realm="\([^"]*\)".*/\1/p')
  NONCE=$(printf '%s' "$challenge" | sed -n 's/.*nonce="\([^"]*\)".*/\1/p')
  HA1=$(printf '%s' "admin:$REALM:$2" | sha256)
  NC=0
}

shelly_rpc() {
  local hdr="" remote nc cnonce ha2 response
  if [ -n "${NONCE:-}" ]; then
    NC=$((NC + 1))
    nc=$(printf '%08x' "$NC")
    cnonce=$(openssl rand -hex 8)
    ha2=$(printf '%s' "POST:/rpc" | sha256)
    # Braces: in zsh `$cnonce:auth` would be the `:a` (absolute path) modifier.
    response=$(printf '%s' "${HA1}:${NONCE}:${nc}:${cnonce}:auth:${ha2}" | sha256)
    hdr="Digest username=\"admin\", realm=\"$REALM\", nonce=\"$NONCE\", uri=\"/rpc\","
    hdr="$hdr qop=auth, nc=$nc, cnonce=\"$cnonce\", algorithm=SHA-256, response=\"$response\""
  fi

  remote="curl -s -m 10 --data-binary @- http://$1/rpc"
  [ -n "$hdr" ] && remote="curl -s -m 10 -H \"Authorization: \$A\" --data-binary @- http://$1/rpc"

  { printf '%s\n' "$hdr"; printf '%s' "$2"; } | ssh root@server "read -r A; $remote"
}

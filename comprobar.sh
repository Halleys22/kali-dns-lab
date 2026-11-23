#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

named-checkconf -z bind/named.conf

log=$(mktemp)
pid=
cleanup() {
    result=$?
    if [[ -n "$pid" ]]; then
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
    fi
    if (( result != 0 )); then cat -- "$log" >&2; fi
    rm -f -- "$log"
}
trap cleanup EXIT

named -g -n 1 -c "$PWD/bind/named.conf" >"$log" 2>&1 &
pid=$!

lookup() {
    dig @127.0.0.1 -p 5300 +tries=1 +time=1 +noall +comments +answer "$@"
}

for attempt in {1..10}; do
    kill -0 "$pid"
    if grep -Fq 'all zones loaded' "$log" && grep -Eq '(^|[[:space:]])running$' "$log"; then
        break
    fi
    sleep 1
done
grep -Eq '(^|[[:space:]])running$' "$log"

answer=$(lookup www.aula.test. A +norecurse)
printf '%s\n' "$answer"
grep -Eq 'flags:.*[[:space:]]aa([[:space:];])' <<<"$answer"
grep -Eq '^www\.aula\.test\.[[:space:]]+[0-9]+[[:space:]]+IN[[:space:]]+A[[:space:]]+127\.0\.0\.1$' <<<"$answer"

answer=$(lookup aula.test. NS +norecurse)
printf '%s\n' "$answer"
grep -Eq '^aula\.test\.[[:space:]]+[0-9]+[[:space:]]+IN[[:space:]]+NS[[:space:]]+ns1\.aula\.test\.$' <<<"$answer"

for entry in 'bloqueado.test. A' 'prueba.bloqueado.test. TXT'; do
    read -r name type <<<"$entry"
    answer=$(lookup "$name" "$type")
    printf '%s\n' "$answer"
    grep -Fq 'status: NXDOMAIN' <<<"$answer"
    grep -Fqi "rpz QNAME NXDOMAIN rewrite ${name%.}" "$log"
done

echo 'Comprobaciones superadas.'

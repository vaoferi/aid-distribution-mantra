#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -ne 8 ]]; then
  echo "Usage: $0 API_BASE ACCOUNT_USERNAME TOKEN_FILE RESULT_FILE PRIMARY_ROOT CABINET_ROOT RUN_ID REMOTE_REF" >&2
  exit 2
fi

api_base="$1"
account_username="$2"
token_file="$3"
result_file="$4"
_primary_root="$5"
_cabinet_root="$6"
run_id="$7"
remote_ref="$8"

work_dir="$(mktemp -d)"
cron_uid=''

cleanup() {
  if [[ -n "$cron_uid" ]]; then
    curl -sS -o /dev/null -X DELETE \
      "$api_base/api/hosting/v1/accounts/$account_username/cron-jobs/$cron_uid" \
      -H "Authorization: Bearer $(cat "$token_file")" \
      -H 'Accept: application/json' || true
  fi
  rm -rf "$work_dir"
}
trap cleanup EXIT

cron_list="$work_dir/cron-list.json"
create_body="$work_dir/cron-create.json"
output_body="$work_dir/cron-output.json"

list_status="$(curl -sS -o "$cron_list" -w '%{http_code}' \
  "$api_base/api/hosting/v1/accounts/$account_username/cron-jobs" \
  -H "Authorization: Bearer $(cat "$token_file")" \
  -H 'Accept: application/json')"

stale_deleted=0
if [[ "$list_status" == '200' ]]; then
  while IFS= read -r stale_uid; do
    [[ -n "$stale_uid" ]] || continue
    curl -sS -o /dev/null -X DELETE \
      "$api_base/api/hosting/v1/accounts/$account_username/cron-jobs/$stale_uid" \
      -H "Authorization: Bearer $(cat "$token_file")" \
      -H 'Accept: application/json' || true
    stale_deleted=$((stale_deleted + 1))
  done < <(jq -r '
    (if type == "array" then . elif (.data | type) == "array" then .data else [] end)[]
    | select((.command // "") | test("NLM_READ_ONLY_|nlm-emergency-|HOSTINGER_CRON_OK_|nlm-remote-diagnostic"))
    | .uid // empty
  ' "$cron_list" 2>/dev/null || true)
fi

echo "STALE_OPERATIONAL_CRONS_DELETED=$stale_deleted" >> "$result_file"

marker="NLM_READ_ONLY_${run_id}"
remote_url="https://raw.githubusercontent.com/vaoferi/aid-distribution-mantra/${remote_ref}/ops/nlm-remote-diagnostic.sh"
command="curl -fsSL '$remote_url' | bash -s -- '$run_id'"
command_length="${#command}"

echo "CRON_COMMAND_LENGTH=$command_length" >> "$result_file"
if (( command_length > 255 )); then
  echo 'CRON_COMMAND_TOO_LONG' >> "$result_file"
  exit 5
fi

payload="$(jq -n --arg time '* * * * *' --arg command "$command" '{time:$time,command:$command}')"
create_status="$(curl -sS -o "$create_body" -w '%{http_code}' \
  -X POST "$api_base/api/hosting/v1/accounts/$account_username/cron-jobs" \
  -H "Authorization: Bearer $(cat "$token_file")" \
  -H 'Content-Type: application/json' \
  --data "$payload")"
cron_uid="$(jq -r '.uid // .data.uid // empty' "$create_body" 2>/dev/null || true)"

{
  echo "CRON_CREATE_STATUS=$create_status"
  echo "CRON_UID=${cron_uid:-NONE}"
} >> "$result_file"

if [[ ! "$create_status" =~ ^20[01]$ ]]; then
  jq -r '.message // .error // "Cron creation failed"' "$create_body" >> "$result_file" 2>/dev/null || true
  exit 6
fi

if [[ -z "$cron_uid" ]]; then
  echo 'CRON_UID_MISSING' >> "$result_file"
  exit 7
fi

observed=0
final_output=''
last_output_status=''

for _attempt in $(seq 1 42); do
  sleep 10
  last_output_status="$(curl -sS -o "$output_body" -w '%{http_code}' \
    "$api_base/api/hosting/v1/accounts/$account_username/cron-jobs/$cron_uid/output" \
    -H "Authorization: Bearer $(cat "$token_file")" \
    -H 'Accept: application/json')"

  final_output="$(jq -r '
    if type == "string" then .
    elif .output != null then .output
    elif .data.output != null then .data.output
    elif .data != null and (.data | type) == "string" then .data
    else empty
    end
  ' "$output_body" 2>/dev/null || true)"

  if grep -Fq "${marker}_END" <<<"$final_output"; then
    observed=1
    break
  fi
done

delete_status="$(curl -sS -o /dev/null -w '%{http_code}' \
  -X DELETE "$api_base/api/hosting/v1/accounts/$account_username/cron-jobs/$cron_uid" \
  -H "Authorization: Bearer $(cat "$token_file")" \
  -H 'Accept: application/json')"
cron_uid=''

{
  echo "CRON_OUTPUT_STATUS=${last_output_status:-NONE}"
  echo "CRON_OBSERVED=$observed"
  echo "CRON_DELETE_STATUS=$delete_status"
  echo '=== PRODUCTION_OUTPUT_BEGIN ==='
  printf '%s\n' "$final_output"
  echo '=== PRODUCTION_OUTPUT_END ==='
} >> "$result_file"

[[ "$observed" -eq 1 ]]

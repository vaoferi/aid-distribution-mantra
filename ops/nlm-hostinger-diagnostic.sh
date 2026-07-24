#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -ne 7 ]]; then
  echo "Usage: $0 API_BASE ACCOUNT_USERNAME TOKEN_FILE RESULT_FILE PRIMARY_ROOT CABINET_ROOT RUN_ID" >&2
  exit 2
fi

api_base="$1"
account_username="$2"
token_file="$3"
result_file="$4"
primary_root="$5"
cabinet_root="$6"
run_id="$7"

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

marker="NLM_READ_ONLY_${run_id}"
php_diag="$work_dir/diagnose.php"
remote_script="$work_dir/diagnose.sh"
create_body="$work_dir/cron-create.json"
output_body="$work_dir/cron-output.json"

cat > "$php_diag" <<'PHP'
<?php

declare(strict_types=1);

use yii\helpers\ArrayHelper;

$root = rtrim((string)($argv[1] ?? ''), '/');
if ($root === '' || !is_file($root . '/vendor/autoload.php')) {
    fwrite(STDERR, "INVALID_PROJECT_ROOT\n");
    exit(2);
}

require $root . '/vendor/autoload.php';
require $root . '/common/env.php';
require $root . '/vendor/yiisoft/yii2/Yii.php';
require $root . '/common/config/bootstrap.php';
require $root . '/console/config/bootstrap.php';

$config = ArrayHelper::merge(
    require $root . '/common/config/base.php',
    require $root . '/common/config/console.php',
    require $root . '/console/config/console.php'
);
new yii\console\Application($config);

$kyiv = new DateTimeZone('Europe/Kyiv');
$from = (new DateTimeImmutable('2026-07-24 00:00:00', $kyiv))->getTimestamp();
$to = (new DateTimeImmutable('2026-07-26 23:59:59', $kyiv))->getTimestamp();
$needle = '%Танкістів%';

$format = static function ($value) use ($kyiv): ?array {
    if ($value === null || $value === '' || (int)$value <= 0) {
        return null;
    }
    $timestamp = (int)$value;
    return [
        'unix' => $timestamp,
        'kyiv' => (new DateTimeImmutable('@' . $timestamp))->setTimezone($kyiv)->format('Y-m-d H:i:s P'),
        'utc' => gmdate('Y-m-d H:i:s', $timestamp) . ' +00:00',
    ];
};

$campaigns = Yii::$app->db->createCommand(
    'SELECT id, title, start_at, end_at, created_at, updated_at, location_name, location_address '
    . 'FROM {{%aid_campaign}} '
    . 'WHERE start_at BETWEEN :from AND :to '
    . 'AND (location_address LIKE :needle OR location_name LIKE :needle OR title LIKE :needle) '
    . 'ORDER BY start_at, id',
    [':from' => $from, ':to' => $to, ':needle' => $needle]
)->queryAll();

$result = [
    'php_timezone' => date_default_timezone_get(),
    'app_timezone' => Yii::$app->timeZone,
    'campaigns' => [],
];

foreach ($campaigns as $campaign) {
    $campaignId = (int)$campaign['id'];
    $counts = Yii::$app->db->createCommand(
        'SELECT COUNT(*) AS total, '
        . 'SUM(CASE WHEN confirmed_at IS NOT NULL THEN 1 ELSE 0 END) AS confirmed, '
        . 'SUM(CASE WHEN status = 3 THEN 1 ELSE 0 END) AS issued, '
        . 'SUM(CASE WHEN slot_id IS NULL THEN 1 ELSE 0 END) AS without_slot '
        . 'FROM {{%aid_campaign_application}} WHERE campaign_id = :campaign_id',
        [':campaign_id' => $campaignId]
    )->queryOne();

    $slots = Yii::$app->db->createCommand(
        'SELECT id, starts_at, ends_at, capacity, available_slots '
        . 'FROM {{%aid_campaign_time_slot}} WHERE campaign_id = :campaign_id ORDER BY starts_at, id',
        [':campaign_id' => $campaignId]
    )->queryAll();

    $slotRows = [];
    foreach ($slots as $slot) {
        $slotRows[] = [
            'id' => (int)$slot['id'],
            'starts_at' => $format($slot['starts_at']),
            'ends_at' => $format($slot['ends_at']),
            'capacity' => (int)$slot['capacity'],
            'available_slots' => (int)$slot['available_slots'],
        ];
    }

    $result['campaigns'][] = [
        'id' => $campaignId,
        'title' => (string)$campaign['title'],
        'location_name' => (string)$campaign['location_name'],
        'location_address' => (string)$campaign['location_address'],
        'start_at' => $format($campaign['start_at']),
        'end_at' => $format($campaign['end_at']),
        'created_at' => $format($campaign['created_at']),
        'updated_at' => $format($campaign['updated_at']),
        'counts' => [
            'total' => (int)($counts['total'] ?? 0),
            'confirmed' => (int)($counts['confirmed'] ?? 0),
            'issued' => (int)($counts['issued'] ?? 0),
            'without_slot' => (int)($counts['without_slot'] ?? 0),
        ],
        'slots' => $slotRows,
    ];
}

echo json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . PHP_EOL;
PHP

php_b64="$(base64 -w0 "$php_diag")"

cat > "$remote_script" <<EOF
set -u
echo '${marker}_BEGIN'
date -u +'UTC=%Y-%m-%dT%H:%M:%SZ'
php -v | head -1
php -r 'foreach (["Europe/Kiev", "Europe/Kyiv"] as \$z) { try { new DateTimeZone(\$z); echo \$z, "=OK\\n"; } catch (Throwable \$e) { echo \$z, "=FAIL\\n"; } }'
for root in '$primary_root' '$cabinet_root'; do
  echo "ROOT=\$root"
  for rel in common/services/AidCampaignDateTimeService.php frontend/modules/user/views/aid/ticket.php; do
    file="\$root/\$rel"
    if [[ -f "\$file" ]]; then
      sha256sum "\$file"
      php -l "\$file"
    else
      echo "MISSING=\$file"
    fi
  done
  ticket="\$root/frontend/modules/user/views/aid/ticket.php"
  if [[ -f "\$ticket" ]]; then
    grep -nE 'Дата та час видачі:|<div class="header-info">Дата:|<div class="header-info">Видача:' "\$ticket" || true
  fi
  if git -C "\$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "GIT_HEAD=\$(git -C "\$root" rev-parse HEAD)"
    git -C "\$root" status --short --untracked-files=no | sed 's/^/GIT_STATUS=/' || true
  else
    echo 'GIT_HEAD=NONE'
  fi
done
php_tmp="/tmp/nlm-ticket-time-${run_id}.php"
printf '%s' '$php_b64' | base64 -d > "\$php_tmp"
php "\$php_tmp" '$primary_root'
php_rc=\$?
rm -f "\$php_tmp"
echo "PHP_DIAGNOSTIC_EXIT=\$php_rc"
echo '${marker}_END'
EOF

script_b64="$(base64 -w0 "$remote_script")"
command="printf '%s' '$script_b64' | base64 -d | bash"
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

for _attempt in $(seq 1 36); do
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

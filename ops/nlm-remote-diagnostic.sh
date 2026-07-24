#!/usr/bin/env bash
set -u

run_id="${1:-unknown}"
marker="NLM_READ_ONLY_${run_id}"
primary_root="$HOME/domains/nlm.help/public_html"
cabinet_root="$HOME/domains/my.nlm.help/public_html"
php_tmp="/tmp/nlm-ticket-time-${run_id}.php"

echo "${marker}_BEGIN"
date -u +'UTC=%Y-%m-%dT%H:%M:%SZ'
printf 'HOME=%s\n' "$HOME"
php -v | head -1
php -r 'foreach (["Europe/Kiev", "Europe/Kyiv"] as $z) { try { new DateTimeZone($z); echo $z, "=OK\n"; } catch (Throwable $e) { echo $z, "=FAIL\n"; } }'

for root in "$primary_root" "$cabinet_root"; do
  echo "ROOT=$root"
  for rel in common/services/AidCampaignDateTimeService.php frontend/modules/user/views/aid/ticket.php; do
    file="$root/$rel"
    if [[ -f "$file" ]]; then
      sha256sum "$file"
      php -l "$file"
    else
      echo "MISSING=$file"
    fi
  done

  ticket="$root/frontend/modules/user/views/aid/ticket.php"
  if [[ -f "$ticket" ]]; then
    grep -nE 'Дата та час видачі:|<div class="header-info">Дата:|<div class="header-info">Видача:' "$ticket" || true
  fi

  if git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "GIT_HEAD=$(git -C "$root" rev-parse HEAD)"
    git -C "$root" status --short --untracked-files=no | sed 's/^/GIT_STATUS=/' || true
  else
    echo 'GIT_HEAD=NONE'
  fi
done

cat > "$php_tmp" <<'PHP'
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

php "$php_tmp" "$primary_root"
php_rc=$?
rm -f "$php_tmp"
echo "PHP_DIAGNOSTIC_EXIT=$php_rc"
echo "${marker}_END"

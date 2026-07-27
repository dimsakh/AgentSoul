#!/usr/bin/env bash
# metrics-collector.sh — вызывается auto-scanner / /knowledge-audit: считает метрики здоровья базы, пишет в state/metrics.md.
# Считает статические метрики из файлов global-lessons/
# Результаты пишет в ~/.claude/hooks/state/metrics.md
# Вызывается из auto-scanner или вручную через /knowledge-audit

set -euo pipefail

PATHS_LIB="${PATHS_LIB:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/paths-lib.sh}"
if [ -f "$PATHS_LIB" ]; then source "$PATHS_LIB"; else : "${LESSONS_DIR:=$HOME/.claude/global-lessons}"; : "${STATE_DIR:=$HOME/.claude/hooks/state}"; fi

KNOWLEDGE_DIR="$LESSONS_DIR"
# STATE_DIR — из paths-lib (источается выше)
METRICS_FILE="$STATE_DIR/metrics.md"
INJECTION_LOG="$STATE_DIR/injection-log.jsonl"
ITR_HISTORY="$STATE_DIR/intrusiveness-history.jsonl"

mkdir -p "$STATE_DIR"

# --- Counts ---
CASES=0
PATTERNS=0
PRINCIPLES=0
TOTAL=0
ACTIVE=0
WEAKENED=0
DEPRECATED=0

TOTAL_CONFIRMED=0
TOTAL_CONTRADICTED=0

FRESH_COUNT=0       # last_confirmed < 30 days
STALE_COUNT=0       # last_confirmed >= 30 days
NO_DATE_COUNT=0     # no last_confirmed

TODAY_EPOCH=$(date +%s)
THIRTY_DAYS=$((30 * 86400))

for file in "$KNOWLEDGE_DIR"/*.md; do
    [ -f "$file" ] || continue
    BASENAME=$(basename "$file")
    [ "$BASENAME" = "META.md" ] && continue

    TOTAL=$((TOTAL + 1))

    # Count by type
    case "$BASENAME" in
        case-*)      CASES=$((CASES + 1)) ;;
        pattern-*)   PATTERNS=$((PATTERNS + 1)) ;;
        principle-*) PRINCIPLES=$((PRINCIPLES + 1)) ;;
    esac

    # Read frontmatter
    FRONTMATTER=$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$file")

    # Status
    STATUS=$(echo "$FRONTMATTER" | grep '^status:' | sed 's/^status:[[:space:]]*//' | tr -d '"' || true)
    case "$STATUS" in
        active|"")  ACTIVE=$((ACTIVE + 1)) ;;
        weakened)   WEAKENED=$((WEAKENED + 1)) ;;
        deprecated) DEPRECATED=$((DEPRECATED + 1)) ;;
    esac

    # Confirmed/contradicted totals
    CONF=$(echo "$FRONTMATTER" | grep '^confirmed_count:' | grep -oE '[0-9]+' | head -1 || true)
    CONTR=$(echo "$FRONTMATTER" | grep '^contradicted_count:' | grep -oE '[0-9]+' | head -1 || true)
    CONF="${CONF:-0}"
    CONTR="${CONTR:-0}"
    TOTAL_CONFIRMED=$((TOTAL_CONFIRMED + CONF))
    TOTAL_CONTRADICTED=$((TOTAL_CONTRADICTED + CONTR))

    # Freshness: last_confirmed within 30 days
    LAST_CONF=$(echo "$FRONTMATTER" | grep '^last_confirmed:' | sed 's/^last_confirmed:[[:space:]]*//' | tr -d '"' || true)
    if [ -n "$LAST_CONF" ] && [ "$LAST_CONF" != "YYYY-MM-DD" ]; then
        # Parse date to epoch
        CONF_EPOCH=$(date -j -f "%Y-%m-%d" "$LAST_CONF" +%s 2>/dev/null || echo "0")
        if [ "$CONF_EPOCH" -gt 0 ]; then
            AGE=$((TODAY_EPOCH - CONF_EPOCH))
            if [ "$AGE" -lt "$THIRTY_DAYS" ]; then
                FRESH_COUNT=$((FRESH_COUNT + 1))
            else
                STALE_COUNT=$((STALE_COUNT + 1))
            fi
        else
            NO_DATE_COUNT=$((NO_DATE_COUNT + 1))
        fi
    else
        NO_DATE_COUNT=$((NO_DATE_COUNT + 1))
    fi
done

# --- Calculate metrics ---

# depth_ratio: principles / (cases + patterns) — target 10-20%
if [ $((CASES + PATTERNS)) -gt 0 ]; then
    DEPTH_RATIO=$(( (PRINCIPLES * 100) / (CASES + PATTERNS) ))
else
    DEPTH_RATIO=0
fi

# freshness: % of knowledge confirmed within 30 days — target > 40%
DATABLE=$((FRESH_COUNT + STALE_COUNT))
if [ "$DATABLE" -gt 0 ]; then
    FRESHNESS=$(( (FRESH_COUNT * 100) / DATABLE ))
else
    FRESHNESS=0
fi

# contradiction_ratio: contradictions / confirmations — target < 20%
if [ "$TOTAL_CONFIRMED" -gt 0 ]; then
    CONTRADICTION_RATIO=$(( (TOTAL_CONTRADICTED * 100) / TOTAL_CONFIRMED ))
else
    CONTRADICTION_RATIO=0
fi

# --- Hit rate from injection log ---
HIT_RATE="n/a"
INJECTIONS_TOTAL=0
UNIQUE_INJECTED=0
UNIQUE_SCORABLE=0
MALFORMED=0
NEVER_INJECTED=""
TOP_INJECTED=""
AVG_SCORE="n/a"
if [ -f "$INJECTION_LOG" ]; then
    LOG_LINES=$({ grep -c '' "$INJECTION_LOG" 2>/dev/null || true; })
    LOG_LINES="${LOG_LINES:-0}"
    INJ_FILES=""
    INJ_SCORES=""
    if command -v jq &>/dev/null; then
        # `jq -rR 'fromjson? // empty'` — канонический устойчивый разбор jsonl проекта.
        # Голый `jq -r '.file'` обрывался на первой битой строке (286 из 7665) и молча
        # отдавал огрызок: 10 уникальных знаний вместо 99, hit_rate 34% вместо реального.
        # `select(.injected != false)` — обратная совместимость: у старых записей поля
        # нет (null != false → true), новые ранги 4-6 (контрольная группа) отсеиваются.
        INJ_FILES=$({ jq -rR 'fromjson? // empty | select(.injected != false) | .file' "$INJECTION_LOG" 2>/dev/null || true; })
        # score 99 — синтетический маркер mcp-semantic fallback, не оценка релевантности;
        # это половина записей, и в среднем они дают 52 вместо реальных ~4.6.
        INJ_SCORES=$({ jq -rR 'fromjson? // empty | select(.injected != false and .score != 99) | .score' "$INJECTION_LOG" 2>/dev/null || true; })
        VALID_LINES=$({ jq -rR 'fromjson? // empty | "x"' "$INJECTION_LOG" 2>/dev/null || true; } | grep -c '' || true)
        MALFORMED=$((LOG_LINES - ${VALID_LINES:-0}))
    else
        # Деградация без jq: та же семантика грубо, средний score недоступен.
        INJ_FILES=$({ grep -v '"injected":false' "$INJECTION_LOG" 2>/dev/null || true; } | \
            grep -oE '"file":"[^"]+"' | cut -d'"' -f4 || true)
    fi

    if [ -n "$INJ_FILES" ]; then
        INJECTIONS_TOTAL=$({ printf '%s\n' "$INJ_FILES" | grep -c '' || true; })
        INJECTIONS_TOTAL="${INJECTIONS_TOTAL:-0}"
        INJECTED_FILES=$(printf '%s\n' "$INJ_FILES" | sort -u)
        UNIQUE_INJECTED=$({ printf '%s\n' "$INJECTED_FILES" | grep -c '' || true; })
        UNIQUE_INJECTED="${UNIQUE_INJECTED:-0}"

        # Top-5 most injected (file + count)
        TOP_INJECTED=$(printf '%s\n' "$INJ_FILES" | sort | uniq -c | sort -rn | head -5 | \
            awk '{printf "  %s (%d раз)\n", $2, $1}' || true)

        # hit_rate И never_injected — один проход по реально существующим на диске
        # pattern/principle. Лог содержит ещё case/fact/relation (их кладёт mcp-fallback),
        # и деление всех уникальных на PATTERNS+PRINCIPLES дало бы 341%. Пересечение с
        # диском заодно отбрасывает призраков — знания, удалённые после инжекта.
        SCORABLE=$((PATTERNS + PRINCIPLES))
        for file in "$KNOWLEDGE_DIR"/pattern-*.md "$KNOWLEDGE_DIR"/principle-*.md; do
            [ -f "$file" ] || continue
            BN=$(basename "$file")
            if printf '%s\n' "$INJECTED_FILES" | grep -Fqx "$BN" 2>/dev/null; then
                UNIQUE_SCORABLE=$((UNIQUE_SCORABLE + 1))
            else
                NEVER_INJECTED="${NEVER_INJECTED}  ${BN}\n"
            fi
        done
        if [ "$SCORABLE" -gt 0 ]; then
            HIT_RATE="$((UNIQUE_SCORABLE * 100 / SCORABLE))%"
        fi

        if [ -n "$INJ_SCORES" ]; then
            AVG_SCORE=$(printf '%s\n' "$INJ_SCORES" | \
                awk '{s+=$1; n++} END{if(n>0) printf "%.1f", s/n; else printf "n/a"}' || echo "n/a")
        fi
    fi
fi

# --- Health assessment ---
HEALTH="✅ Здоровая"
WARNINGS=""

if [ "$DEPTH_RATIO" -lt 5 ]; then
    WARNINGS="${WARNINGS}\n- ⚠️ depth_ratio ${DEPTH_RATIO}% < 5% — мало обобщений, только частные случаи"
fi
if [ "$DEPTH_RATIO" -gt 30 ]; then
    WARNINGS="${WARNINGS}\n- ⚠️ depth_ratio ${DEPTH_RATIO}% > 30% — слишком много обобщений без кейсов"
fi
if [ "$FRESHNESS" -lt 20 ]; then
    WARNINGS="${WARNINGS}\n- ⚠️ freshness ${FRESHNESS}% < 20% — знания устаревают быстрее чем обновляются"
fi
if [ "$CONTRADICTION_RATIO" -gt 20 ]; then
    WARNINGS="${WARNINGS}\n- ⚠️ contradiction_ratio ${CONTRADICTION_RATIO}% > 20% — много противоречий"
fi
if [ "$WEAKENED" -gt 0 ]; then
    WARNINGS="${WARNINGS}\n- ⚠️ ${WEAKENED} weakened знаний — требуют ревью"
fi

if [ -n "$WARNINGS" ]; then
    HEALTH="⚠️ Требует внимания"
fi

# --- Intrusiveness trends (v1.3.2) ---
# Reads ~/.claude/hooks/state/intrusiveness-history.jsonl (one JSON line per
# closed session). Computes last-20 aggregates and trend vs prev-20.
# Feeds H13 (gentle_acceptance_rate), H14 (override_freq), H15 (debt_carryover).
#
# Output: global ITR_TRENDS_BLOCK (markdown, injected below), plus warnings.
ITR_TRENDS_BLOCK=""
ITR_SESSIONS_TOTAL=0
ITR_ACCEPTANCE_RATE="n/a"
if [ -f "$ITR_HISTORY" ] && command -v jq >/dev/null 2>&1; then
    ITR_SESSIONS_TOTAL=$(wc -l < "$ITR_HISTORY" | tr -d ' ')
fi

# Helper: compute aggregates for a JSONL slice on stdin → emits space-separated
# fields (17): sessions gentle_accepted gentle_ignored proactive override
# debt_surfaced debt_pending_sessions acceptance_pct avg_events avg_duration
# timing_peak_avg silence_peak_avg closing_avg
# focus_pct stuck_pct exploration_pct idle_pct
#
# State distribution percentages (fields 14-17, v1.3.3) are computed across
# all classified prompts in the slice — sum(distribution[state]) / sum(all).
# Sessions closed under schema < v3 contribute zeros and don't distort ratios.
_itr_aggregate() {
    jq -sr '
        . as $s
        | ($s | length) as $n
        | if $n == 0 then
            "0 0 0 0 0 0 0 n/a 0 0 0 0 0 n/a n/a n/a n/a"
          else
            (([.[] | .state_distribution.focus       // 0] | add)) as $sf
            | (([.[] | .state_distribution.stuck       // 0] | add)) as $ss
            | (([.[] | .state_distribution.exploration // 0] | add)) as $se
            | (([.[] | .state_distribution.idle        // 0] | add)) as $si
            | ($sf + $ss + $se + $si) as $st
            | [
              $n,
              ([.[] | .metrics.gentle_accepted       // 0] | add),
              ([.[] | .metrics.gentle_ignored        // 0] | add),
              ([.[] | .metrics.proactive_events      // 0] | add),
              ([.[] | .metrics.override_events       // 0] | add),
              ([.[] | .metrics.silence_debt_surfaced // 0] | add),
              ([.[] | select((.debt.pending // 0) > 0)] | length),
              (
                ([.[] | .metrics.gentle_accepted // 0] | add) as $a
                | ([.[] | .metrics.gentle_ignored // 0] | add) as $i
                | if ($a + $i) == 0 then "n/a"
                  else (($a * 100) / ($a + $i) | floor | tostring) end
              ),
              (([.[] | .events_total // 0] | add) / $n | floor),
              (([.[] | .duration_min // 0] | add) / $n | floor),
              (([.[] | .cost_peaks.timing_max // 0]  | add) * 10 / $n | floor / 10),
              (([.[] | .cost_peaks.silence_max // 0] | add) * 10 / $n | floor / 10),
              (([.[] | .cost_peaks.closing // 0]     | add) * 10 / $n | floor / 10),
              (if $st == 0 then "n/a" else (($sf * 100) / $st | floor | tostring) end),
              (if $st == 0 then "n/a" else (($ss * 100) / $st | floor | tostring) end),
              (if $st == 0 then "n/a" else (($se * 100) / $st | floor | tostring) end),
              (if $st == 0 then "n/a" else (($si * 100) / $st | floor | tostring) end)
            ] | join(" ")
          end
    ' 2>/dev/null || echo "0 0 0 0 0 0 0 n/a 0 0 0 0 0 n/a n/a n/a n/a"
}

if [ "$ITR_SESSIONS_TOTAL" -gt 0 ] && command -v jq >/dev/null 2>&1; then
    # Slice 1: last 20 sessions
    LAST20=$(tail -20 "$ITR_HISTORY" | _itr_aggregate)
    # Slice 2: prev 20 (sessions 21..40 from the end)
    PREV20=""
    if [ "$ITR_SESSIONS_TOTAL" -gt 20 ]; then
        PREV20=$(tail -40 "$ITR_HISTORY" | head -20 | _itr_aggregate)
    fi

    # Parse last20 fields (13 legacy + 4 state-distribution percentages)
    read -r L_N L_ACC L_IGN L_PRO L_OVR L_SURF L_DEBTS L_ACCPCT L_AVGEV L_AVGDUR L_TIM L_SIL L_CLO L_FOC L_STK L_EXP L_IDL <<< "$LAST20"
    ITR_ACCEPTANCE_RATE="${L_ACCPCT}%"

    # Trend arrow helper: compare last vs prev for a numeric field.
    # Echoes "↑", "↓", "→", or "" (no prev).
    _itr_arrow() {
        local cur="$1" prev="$2"
        [ -z "$prev" ] && { echo ""; return; }
        [ "$cur" = "$prev" ] && { echo "→"; return; }
        # awk handles floats from the aggregates above
        awk -v c="$cur" -v p="$prev" 'BEGIN { if (c+0 > p+0) print "↑"; else if (c+0 < p+0) print "↓"; else print "→" }'
    }

    ARROW_ACCPCT=""
    ARROW_OVR=""
    ARROW_DEBTS=""
    if [ -n "$PREV20" ]; then
        read -r P_N P_ACC P_IGN P_PRO P_OVR P_SURF P_DEBTS P_ACCPCT P_AVGEV P_AVGDUR P_TIM P_SIL P_CLO P_FOC P_STK P_EXP P_IDL <<< "$PREV20"
        # Acceptance arrow: only if both have numeric value
        if [ "$L_ACCPCT" != "n/a" ] && [ "$P_ACCPCT" != "n/a" ]; then
            ARROW_ACCPCT=$(_itr_arrow "$L_ACCPCT" "$P_ACCPCT")
        fi
        ARROW_OVR=$(_itr_arrow "$L_OVR" "$P_OVR")
        # debt_carryover trend: compare % of sessions with pending debt
        L_DEBTPCT=$(awk -v d="$L_DEBTS" -v n="$L_N" 'BEGIN { if (n>0) print int(d*100/n); else print 0 }')
        P_DEBTPCT=$(awk -v d="$P_DEBTS" -v n="$P_N" 'BEGIN { if (n>0) print int(d*100/n); else print 0 }')
        ARROW_DEBTS=$(_itr_arrow "$L_DEBTPCT" "$P_DEBTPCT")
    fi

    # Warnings for intrusiveness trends
    if [ "$L_ACCPCT" != "n/a" ] && [ "$L_ACCPCT" -lt 30 ] 2>/dev/null; then
        WARNINGS="${WARNINGS}\n- ⚠️ gentle_acceptance_rate ${L_ACCPCT}% < 30% — cost model miscalibrated, слишком много gentle игнорируется"
    fi
    # Override budget audit: per risk table in PLAN Phase 13
    # If overrides > 20% of (gentle+proactive+override) — miscalibrated
    OVR_TOTAL=$((L_ACC + L_IGN + L_PRO + L_OVR))
    if [ "$OVR_TOTAL" -gt 0 ] && [ "$L_OVR" -gt 0 ]; then
        OVR_PCT=$(( L_OVR * 100 / OVR_TOTAL ))
        if [ "$OVR_PCT" -gt 20 ]; then
            WARNINGS="${WARNINGS}\n- ⚠️ override rate ${OVR_PCT}% > 20% — emergency override размывается, cost model miscalibrated"
        fi
    fi

    # State-distribution warnings (v1.3.3): persistent stuck signal or
    # missing classifier data both deserve attention.
    if [ "$L_STK" != "n/a" ] && [ "$L_STK" -gt 30 ] 2>/dev/null; then
        WARNINGS="${WARNINGS}\n- ⚠️ state stuck ${L_STK}% > 30% — агент видит собеседника застрявшим чаще, чем нормально. Проверить: повторяющиеся ошибки, пропущенные root-cause расследования"
    fi

    # Build markdown block
    {
        echo ""
        echo "## Intrusiveness trends (L6 gate)"
        echo "**Источник:** \`$ITR_HISTORY\`"
        echo "**Сессий всего:** $ITR_SESSIONS_TOTAL"
        echo ""
        if [ "$ITR_SESSIONS_TOTAL" -lt 20 ]; then
            echo "_Недостаточно данных для trend-анализа (нужно ≥ 20 закрытых сессий, есть $ITR_SESSIONS_TOTAL)._"
            echo ""
            echo "### Кумулятивные метрики"
        else
            echo "### Последние 20 сессий"
        fi
        echo ""
        echo "| Метрика | Last 20 | Prev 20 | Trend |"
        echo "|---------|---------|---------|-------|"
        echo "| gentle accepted / ignored | ${L_ACC} / ${L_IGN} | ${P_ACC:-—} / ${P_IGN:-—} | |"
        if [ "$L_ACCPCT" = "n/a" ]; then
            echo "| gentle_acceptance_rate | n/a | ${P_ACCPCT:-—} | |"
        else
            echo "| gentle_acceptance_rate | ${L_ACCPCT}% | ${P_ACCPCT:-—}${P_ACCPCT:+%} | ${ARROW_ACCPCT} |"
        fi
        echo "| proactive events | ${L_PRO} | ${P_PRO:-—} | |"
        echo "| override events | ${L_OVR} | ${P_OVR:-—} | ${ARROW_OVR} |"
        echo "| debt surfaced / pending sessions | ${L_SURF} / ${L_DEBTS} | ${P_SURF:-—} / ${P_DEBTS:-—} | ${ARROW_DEBTS} |"
        echo "| avg events/session | ${L_AVGEV} | ${P_AVGEV:-—} | |"
        echo "| avg duration (min) | ${L_AVGDUR} | ${P_AVGDUR:-—} | |"
        echo "| avg cost_peaks (timing/silence/closing) | ${L_TIM} / ${L_SIL} / ${L_CLO} | ${P_TIM:-—} / ${P_SIL:-—} / ${P_CLO:-—} | |"
        # State distribution (v1.3.3) — only surface if classifier has data.
        if [ "$L_FOC" != "n/a" ] || [ "$L_STK" != "n/a" ] || [ "$L_EXP" != "n/a" ] || [ "$L_IDL" != "n/a" ]; then
            _fmt_pct() { if [ "$1" = "n/a" ]; then echo "—"; else echo "${1}%"; fi; }
            echo "| state focus/stuck/exploration/idle | $(_fmt_pct "$L_FOC") / $(_fmt_pct "$L_STK") / $(_fmt_pct "$L_EXP") / $(_fmt_pct "$L_IDL") | $(_fmt_pct "${P_FOC:-n/a}") / $(_fmt_pct "${P_STK:-n/a}") / $(_fmt_pct "${P_EXP:-n/a}") / $(_fmt_pct "${P_IDL:-n/a}") | |"
        fi
    } > "$STATE_DIR/.itr-trends.md.tmp"
    ITR_TRENDS_BLOCK=$(cat "$STATE_DIR/.itr-trends.md.tmp")
    rm -f "$STATE_DIR/.itr-trends.md.tmp"
fi

# --- Write results ---
{
    echo "# Метрики здоровья системы знаний"
    echo "**Дата:** $(date '+%Y-%m-%d %H:%M')"
    echo "**Оценка:** $HEALTH"
    echo ""
    echo "## Состав базы"
    echo "| Тип | Количество |"
    echo "|-----|------------|"
    echo "| Cases | $CASES |"
    echo "| Patterns | $PATTERNS |"
    echo "| Principles | $PRINCIPLES |"
    echo "| **Всего** | **$TOTAL** |"
    echo ""
    echo "| Статус | Количество |"
    echo "|--------|------------|"
    echo "| Active | $ACTIVE |"
    echo "| Weakened | $WEAKENED |"
    echo "| Deprecated | $DEPRECATED |"
    echo ""
    echo "## Метрики"
    echo "| Метрика | Значение | Норма | Статус |"
    echo "|---------|----------|-------|--------|"
    if [ "$DEPTH_RATIO" -ge 5 ] && [ "$DEPTH_RATIO" -le 30 ]; then
        echo "| depth_ratio | ${DEPTH_RATIO}% | 10-20% | ✅ |"
    else
        echo "| depth_ratio | ${DEPTH_RATIO}% | 10-20% | ⚠️ |"
    fi
    if [ "$FRESHNESS" -ge 40 ]; then
        echo "| freshness | ${FRESHNESS}% | >40% | ✅ |"
    elif [ "$FRESHNESS" -ge 20 ]; then
        echo "| freshness | ${FRESHNESS}% | >40% | ⚡ |"
    else
        echo "| freshness | ${FRESHNESS}% | >40% | ⚠️ |"
    fi
    if [ "$CONTRADICTION_RATIO" -le 20 ]; then
        echo "| contradiction_ratio | ${CONTRADICTION_RATIO}% | <20% | ✅ |"
    else
        echo "| contradiction_ratio | ${CONTRADICTION_RATIO}% | <20% | ⚠️ |"
    fi
    echo "| hit_rate | ${HIT_RATE} | >30% | $([ "$HIT_RATE" = "n/a" ] && echo "📋" || echo "✅") |"
    echo ""
    echo "## Детали"
    echo "- Подтверждений всего: $TOTAL_CONFIRMED"
    echo "- Противоречий всего: $TOTAL_CONTRADICTED"
    echo "- Свежих (<30д): $FRESH_COUNT"
    echo "- Устаревших (>30д): $STALE_COUNT"
    echo "- Без даты: $NO_DATE_COUNT"
    echo "- Инжекций (из лога): $INJECTIONS_TOTAL"
    echo "- Уникальных знаний инжектировано: $UNIQUE_INJECTED"
    echo "- Из них pattern/principle: $UNIQUE_SCORABLE из $((PATTERNS + PRINCIPLES)) (= hit_rate)"
    echo "- Средний score инжекции: $AVG_SCORE (keyword; mcp-fallback score=99 не учитан)"
    if [ "${MALFORMED:-0}" -gt 0 ]; then
        # Без этой строки поломка разбора невидима: hit_rate 34% выглядел правдоподобно
        # три месяца, пока считался по 285 строкам из 7665.
        echo "- ⚠️ Битых строк в injection-log: $MALFORMED (пропущены при разборе)"
    fi
    echo ""
    echo "## Injection Analytics"
    if [ -n "$TOP_INJECTED" ]; then
        echo "### Top-5 инжектируемых знаний"
        echo "$TOP_INJECTED"
    fi
    if [ -n "$NEVER_INJECTED" ]; then
        echo ""
        echo "### Patterns/principles без инжекций (potential dead weight)"
        echo -e "$NEVER_INJECTED"
    fi
    if [ -n "$ITR_TRENDS_BLOCK" ]; then
        echo "$ITR_TRENDS_BLOCK"
    fi
    if [ -n "$WARNINGS" ]; then
        echo ""
        echo "## Предупреждения"
        echo -e "$WARNINGS"
    fi
} > "$METRICS_FILE"

# --- Calibration progress (v1.4.0 Phase 3 step 3.1) ---
# Counts "valid chunks" in intrusiveness-history.jsonl = entries with a
# chunk boundary (stop|precompact, added in v1.3.8) AND at least one
# gentle/proactive event. Writes state/calibration-progress.json for
# session-start.sh to surface as startup signal.
#
# Valid chunk ≠ closed session. A session may produce multiple chunks
# (PreCompact snapshots + final Stop). Empty chunks (events_total == 0
# or pre-v1.3.8 legacy lines without boundary) don't count — they carry
# no gate data.
#
# Threshold 30 comes from Phase 3 criterion. Once reached, /calibrate
# (scripts/calibrate.py, step 3.3) has enough distribution to recommend
# constants for intrusiveness-state-lib.sh.
CALIB_PROGRESS="$STATE_DIR/calibration-progress.json"
CALIB_VALID=0
CALIB_GENTLE=0
CALIB_PROACTIVE=0
if [ -f "$ITR_HISTORY" ] && command -v jq >/dev/null 2>&1; then
    CALIB_AGG=$(jq -sr '
        [.[]
         | select((.boundary // "") == "stop" or (.boundary // "") == "precompact")
         | select(((.metrics.gentle_accepted // 0)
                  + (.metrics.gentle_ignored // 0)
                  + (.metrics.proactive_events // 0)) > 0)
        ] as $chunks
        | {
            valid: ($chunks | length),
            gentle: ([$chunks[] | (.metrics.gentle_accepted // 0) + (.metrics.gentle_ignored // 0)] | add // 0),
            proactive: ([$chunks[] | .metrics.proactive_events // 0] | add // 0)
          }
        | "\(.valid) \(.gentle) \(.proactive)"
    ' "$ITR_HISTORY" 2>/dev/null || echo "0 0 0")
    read -r CALIB_VALID CALIB_GENTLE CALIB_PROACTIVE <<< "$CALIB_AGG"
    CALIB_VALID="${CALIB_VALID:-0}"
    CALIB_GENTLE="${CALIB_GENTLE:-0}"
    CALIB_PROACTIVE="${CALIB_PROACTIVE:-0}"
fi
CALIB_NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
printf '{"valid_chunks":%d,"gentle_events_total":%d,"proactive_events_total":%d,"threshold":30,"last_updated":"%s"}\n' \
    "$CALIB_VALID" "$CALIB_GENTLE" "$CALIB_PROACTIVE" "$CALIB_NOW" > "$CALIB_PROGRESS"

# Output for caller (auto-scanner or direct)
if [ "$ITR_SESSIONS_TOTAL" -gt 0 ]; then
    echo "Metrics collected: $TOTAL knowledge files, health: $HEALTH; intrusiveness: $ITR_SESSIONS_TOTAL sessions (gentle acceptance: $ITR_ACCEPTANCE_RATE); calibration: $CALIB_VALID/30 valid chunks"
else
    echo "Metrics collected: $TOTAL knowledge files, health: $HEALTH; calibration: $CALIB_VALID/30 valid chunks"
fi

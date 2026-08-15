#!/usr/bin/env bash
# test-book-parse.sh — /book/parse 接口联调验证脚本
# 跑接口文档 §8 的全部 12 条用例，按响应时间检测超时风险。
#
# 用法：
#   TOKEN=<裸JWT> bash scripts/test-book-parse.sh
#
# 获取 TOKEN 方式（DEBUG 包）：
#   在 Xcode 控制台打印 [[UserInfo shareUserInfo] getAuthorizationToken]
#   或在模拟器 lldb: po [[UserInfo shareUserInfo] getAuthorizationToken]

set -euo pipefail

HOST="https://api.vance.xin"
ENDPOINT="${HOST}/book/parse"
APP_ID="638c2977f1b24ba0"
TODAY="$(date +%Y-%m-%d)"  # 运行当天（后端默认日期基准）
CLIENT_TIMEOUT=2.0        # 客户端硬超时（秒）
WARN_THRESHOLD=1.2        # 超过此值打警告（P50 目标）

if [[ -z "${TOKEN:-}" ]]; then
  echo "❌  缺少 TOKEN 环境变量"
  echo "   用法: TOKEN=<裸JWT> bash $0"
  exit 1
fi

# python3 是 macOS 自带，不依赖 jq
if ! command -v python3 &>/dev/null; then
  echo "❌  需要 python3（macOS 自带，应该已存在）"; exit 1
fi

PASS=0; FAIL=0; WARN=0

# 颜色
GREEN="\033[0;32m"; RED="\033[0;31m"; YELLOW="\033[0;33m"; RESET="\033[0m"

# run_case <编号> <输入文本> <期望price> <期望categoryName> <期望isIncome:true/false> <期望date:YYYY-MM-DD或—>
run_case() {
  local num="$1" text="$2" exp_price="$3" exp_cat="$4" exp_income="$5" exp_date="$6"

  # curl：-w 追加响应时间，-o 捕获 body，-s 静默
  local tmpfile
  tmpfile=$(mktemp)
  local time_s
  time_s=$(curl -s -o "$tmpfile" -w "%{time_total}" \
    --max-time 3 \
    -X POST "$ENDPOINT" \
    -H "Content-Type: application/json; charset=UTF-8" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "app_id: ${APP_ID}" \
    -d "{\"text\": \"${text}\"}" 2>&1) || { echo "  curl 失败"; FAIL=$((FAIL+1)); rm -f "$tmpfile"; return; }

  local json
  json=$(cat "$tmpfile"); rm -f "$tmpfile"

  # 解析 JSON
  local code got_price got_cat got_income got_date
  read -r code got_price got_cat got_income got_date < <(python3 - "$json" <<'PYEOF'
import sys, json

raw = sys.argv[1]
try:
    d = json.loads(raw)
except Exception:
    print("? ? ? ? ?")
    sys.exit(0)

code = d.get("code", "?")
data = d.get("data") or {}
price   = data.get("price", "?")
cat     = data.get("categoryName", "?")
income  = str(data.get("income", "?")).lower()
date    = data.get("date", "—")   # 不存在时用 "—"
print(code, price, cat, income, date)
PYEOF
)

  # 验证逻辑
  local ok=1 reasons=()

  [[ "$code" != "0" ]] && { ok=0; reasons+=("code=${code}"); }

  # price 浮点比较（允许±0.005）
  if [[ "$exp_price" != "?" && "$got_price" != "?" ]]; then
    local price_ok
    price_ok=$(python3 -c "print('1' if abs(float('${got_price}') - float('${exp_price}')) < 0.005 else '0')" 2>/dev/null) || price_ok=0
    [[ "$price_ok" != "1" ]] && { ok=0; reasons+=("price=${got_price}(期望${exp_price})"); }
  fi

  [[ "$got_cat" != "$exp_cat" ]] && { ok=0; reasons+=("categoryName=${got_cat}(期望${exp_cat})"); }
  [[ "$got_income" != "$exp_income" ]] && { ok=0; reasons+=("isIncome=${got_income}(期望${exp_income})"); }

  if [[ "$exp_date" == "—" ]]; then
    # 未提及日期时后端默认今天，接受 TODAY 或缺省
    [[ "$got_date" != "—" && "$got_date" != "$TODAY" ]] && { ok=0; reasons+=("date=${got_date}(期望今天${TODAY}或缺省)"); }
  else
    [[ "$got_date" != "$exp_date" ]] && { ok=0; reasons+=("date=${got_date}(期望${exp_date})"); }
  fi

  # 响应时间检查
  local time_warn=""
  if python3 -c "exit(0 if float('${time_s}') > ${WARN_THRESHOLD} else 1)" 2>/dev/null; then
    time_warn=" ⚠️ 慢"
    WARN=$((WARN+1))
  fi

  # 输出一行
  local status
  if [[ "$ok" == "1" ]]; then
    status="${GREEN}✅ PASS${RESET}"
    PASS=$((PASS+1))
  else
    status="${RED}❌ FAIL${RESET}"
    FAIL=$((FAIL+1))
  fi

  printf "%2s  %-40s  %6ss  %b%s\n" \
    "#${num}" "${text:0:38}" "${time_s}" "$status" "$time_warn"

  if [[ "$ok" == "0" ]]; then
    for r in "${reasons[@]}"; do
      printf "     ${YELLOW}↳ %s${RESET}\n" "$r"
    done
  fi
}

echo "========================================================================"
echo " POST ${ENDPOINT}"
echo " 基准日期 ${TODAY}  |  客户端超时 ${CLIENT_TIMEOUT}s"
echo "========================================================================"
printf "%2s  %-40s  %8s  %s\n" "##" "输入文本" "耗时" "结果"
echo "------------------------------------------------------------------------"

# 接口文档 §8 全部 12 条用例
run_case  1  "昨天打车花了35块"             "35.0"   "交通"   "false"  "2026-08-14"
run_case  2  "三十五块八吃午饭"             "35.8"   "餐饮"   "false"  "—"
run_case  3  "收到报销两百"                "200.0"  "报销"   "true"   "—"
run_case  4  "给老妈转了一千"              "1000.0" "亲友"   "false"  "—"
run_case  5  "发工资了5000"               "5000.0" "工资"   "true"   "—"
run_case  6  "话费交了99"                 "99.0"   "通讯"   "false"  "—"
run_case  7  "淘宝买了件衣服两百多"         "200.0"  "服饰"   "false"  "—"
run_case  8  "和老王吃饭AA我付了六十多"     "60.0"   "餐饮"   "false"  "—"
run_case  9  "买了瓶矿泉水两块五"           "2.5"    "饮料"   "false"  "—"
run_case 10  "8月3号健身房月卡299"         "299.0"  "运动"   "false"  "2026-08-03"
run_case 11  "还了信用卡一千五"            "1500.0" "信用卡" "false"  "—"
run_case 12  "收到红包六十六"              "66.0"   "红包"   "true"   "—"

echo "------------------------------------------------------------------------"
echo ""
printf "结果：${GREEN}%d 通过${RESET} / ${RED}%d 失败${RESET}" "$PASS" "$FAIL"
[[ $WARN -gt 0 ]] && printf " / ${YELLOW}%d 条耗时 > %.1fs（P50目标）${RESET}" "$WARN" "$WARN_THRESHOLD"
echo ""
echo "========================================================================"
[[ $FAIL -gt 0 ]] && exit 1 || exit 0

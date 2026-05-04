#!/system/bin/sh
MODID="usb_role_switch"
STATE_DIR="/data/adb/usb_role_switch"
LOG="$STATE_DIR/usb-role.log"
OLD_LOG="$STATE_DIR/usb-power.log"
DEFAULT_PORT="/sys/class/typec/port0"
PORT_ENV="${USB_TYPEC_PORT:-}"
mkdir -p "$STATE_DIR" 2>/dev/null
[ -f "$LOG" ] || : > "$LOG" 2>/dev/null
[ -f "$OLD_LOG" ] || ln -s "$LOG" "$OLD_LOG" 2>/dev/null || : > "$OLD_LOG" 2>/dev/null
now() { date '+%Y-%m-%d %H:%M:%S'; }
log() { echo "$(now) $*" >> "$LOG" 2>/dev/null; }
pick_port() {
  if [ -n "$PORT_ENV" ] && [ -d "$PORT_ENV" ]; then echo "$PORT_ENV"; return 0; fi
  if [ -d "$DEFAULT_PORT" ]; then echo "$DEFAULT_PORT"; return 0; fi
  for d in /sys/class/typec/port*; do
    [ -d "$d" ] || continue
    case "$d" in *-partner*) continue ;; esac
    echo "$d"
    return 0
  done
  return 1
}
PORT="$(pick_port)"
raw() {
  if [ -r "$1" ]; then cat "$1"; else echo "<missing>"; fi
}
active_role() {
  [ -r "$1" ] || return 1
  sed -n 's/.*\[\([^]]*\)\].*/\1/p' "$1" | head -n 1
}
partner_state() {
  if [ -n "$PORT" ] && [ -d "$PORT-partner" ]; then echo "present"; else echo "not present"; fi
}
list_ports() {
  found=0
  for d in /sys/class/typec/port*; do
    [ -d "$d" ] || continue
    case "$d" in *-partner*) continue ;; esac
    echo "  - $d"
    found=1
  done
  [ "$found" = "1" ] || echo "  - <none>"
}
status() {
  echo "=== USB Role Switch status ==="
  echo "time: $(now)"
  if [ -z "$PORT" ]; then
    echo "port: <none>"
    echo "error: /sys/class/typec/port* not found"
    return 1
  fi
  echo "port: $PORT"
  echo "power_role: $(raw "$PORT/power_role")"
  echo "data_role: $(raw "$PORT/data_role")"
  echo "preferred_role: $(raw "$PORT/preferred_role")"
  echo "power_operation_mode: $(raw "$PORT/power_operation_mode")"
  echo "partner: $(partner_state)"
  echo "available_ports:"
  list_ports
}
note_partner() {
  if [ "$(partner_state)" = "not present" ]; then
    echo "note: no USB partner detected; some drivers reject role changes without an attached device"
  fi
}
write_role() {
  kind="$1"
  value="$2"
  file="$3"
  if [ -z "$PORT" ]; then
    echo "FAIL $kind=$value: no Type-C port found"
    log "FAIL $kind=$value no_port"
    return 1
  fi
  if [ ! -e "$file" ]; then
    echo "SKIP $kind=$value: node not found"
    log "SKIP $kind=$value node_not_found file=$file"
    return 2
  fi
  before="$(raw "$file")"
  if echo "$before" | grep -q "\[$value\]"; then
    echo "OK $kind=$value already active"
    echo "  current: $before"
    log "OK $kind=$value already_active current=[$before]"
    return 0
  fi
  err="$STATE_DIR/write-$kind-$$.err"
  : > "$err" 2>/dev/null
  ( printf '%s' "$value" > "$file" ) 2>"$err"
  rc=$?
  sleep 0.25
  after="$(raw "$file")"
  msg="$(cat "$err" 2>/dev/null)"
  rm -f "$err" 2>/dev/null
  if echo "$after" | grep -q "\[$value\]"; then
    echo "OK $kind=$value"
    echo "  before: $before"
    echo "  after : $after"
    [ -n "$msg" ] && echo "  note  : $msg"
    log "OK $kind=$value rc=$rc before=[$before] after=[$after] note=[$msg]"
    return 0
  fi
  echo "FAIL $kind=$value rc=$rc"
  echo "  before: $before"
  echo "  after : $after"
  [ -n "$msg" ] && echo "  error : $msg"
  log "FAIL $kind=$value rc=$rc before=[$before] after=[$after] error=[$msg]"
  return 1
}
set_power() {
  value="$1"
  case "$value" in source|sink) ;; *) echo "invalid power role: $value"; return 2 ;; esac
  log "REQUEST power_role=$value"
  echo "=== Set power_role=$value ==="
  note_partner
  write_role "power_role" "$value" "$PORT/power_role"
  echo ""
  status
}
set_data() {
  value="$1"
  case "$value" in host|device) ;; *) echo "invalid data role: $value"; return 2 ;; esac
  log "REQUEST data_role=$value"
  echo "=== Set data_role=$value ==="
  note_partner
  write_role "data_role" "$value" "$PORT/data_role"
  echo ""
  status
}
set_pair() {
  p="$1"
  d="$2"
  log "REQUEST pair power_role=$p data_role=$d"
  echo "=== Set power_role=$p, data_role=$d ==="
  note_partner
  write_role "power_role" "$p" "$PORT/power_role"
  sleep 0.25
  write_role "data_role" "$d" "$PORT/data_role"
  echo ""
  status
}
toggle_power() {
  if [ -z "$PORT" ]; then status; return 1; fi
  cur="$(active_role "$PORT/power_role")"
  if [ "$cur" = "source" ]; then set_power sink; else set_power source; fi
}
toggle_data() {
  if [ -z "$PORT" ]; then status; return 1; fi
  cur="$(active_role "$PORT/data_role")"
  if [ "$cur" = "host" ]; then set_data device; else set_data host; fi
}
toggle_pair() {
  if [ -z "$PORT" ]; then status; return 1; fi
  p="$(active_role "$PORT/power_role")"
  d="$(active_role "$PORT/data_role")"
  if [ "$p" = "source" ] || [ "$d" = "host" ]; then set_pair sink device; else set_pair source host; fi
}
show_log() {
  echo "=== log: $LOG ==="
  if [ -r "$LOG" ]; then tail -n 220 "$LOG"; else echo "<no log>"; fi
}
clear_log() {
  : > "$LOG" 2>/dev/null
  [ -L "$OLD_LOG" ] || : > "$OLD_LOG" 2>/dev/null
  log "LOG cleared"
  echo "Log cleared"
}
diag() {
  echo "=== identity ==="
  id
  echo ""
  status
  echo ""
  echo "=== node permissions ==="
  if [ -n "$PORT" ]; then ls -l "$PORT"/power_role "$PORT"/data_role "$PORT"/preferred_role "$PORT"/power_operation_mode 2>/dev/null; fi
  echo ""
  echo "=== sysfs candidates ==="
  find /sys/class/typec /sys/class/dual_role_usb /sys/class/power_supply -maxdepth 3 \( -iname '*role*' -o -iname '*otg*' -o -iname '*typec*' -o -iname '*usb*' \) 2>/dev/null | head -n 240
}
action_view() {
  echo "USB Role Switch"
  echo "Author: GitHub ciallothu"
  echo "Repository: github.com/ciallothu/usb_role_switch"
  echo ""
  status
  echo ""
  show_log
}
usage() {
  cat <<EOF
Usage: $0 <command>
Commands:
  status
  power-source
  power-sink
  power-toggle
  data-host
  data-device
  data-toggle
  source-host
  sink-device
  pair-toggle
  log
  clear-log
  diag
  action
EOF
}
case "$1" in
  status) status ;;
  boot-status) status >/dev/null 2>&1; log "BOOT status captured" ;;
  power-source|source-power|source) set_power source ;;
  power-sink|sink-power|sink) set_power sink ;;
  power-toggle|toggle-power) toggle_power ;;
  data-host|host-data|host) set_data host ;;
  data-device|device-data|device) set_data device ;;
  data-toggle|toggle-data) toggle_data ;;
  source-host|host-source) set_pair source host ;;
  sink-device|device-sink|normal) set_pair sink device ;;
  pair-toggle|toggle|toggle-pair) toggle_pair ;;
  log) show_log ;;
  clear-log) clear_log ;;
  diag|diagnose) diag ;;
  action) action_view ;;
  *) usage; exit 1 ;;
esac

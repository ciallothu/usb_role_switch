#!/system/bin/sh
MODDIR=${0%/*}
[ -x "$MODDIR/bin/usb-role.sh" ] && "$MODDIR/bin/usb-role.sh" boot-status >/dev/null 2>&1

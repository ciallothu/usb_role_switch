#!/system/bin/sh
MODDIR=${0%/*}
SCRIPT="$MODDIR/bin/usb-role.sh"
if [ ! -x "$SCRIPT" ]; then
  echo "USB Role Switch"
  echo "script not found: $SCRIPT"
  exit 0
fi
"$SCRIPT" action
exit 0

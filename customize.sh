#!/system/bin/sh
ui_print "- Installing USB Role Switch"
ui_print "- Author: GitHub ciallothu"
ui_print "- Repository: github.com/ciallothu/usb_role_switch"
ui_print "- No USB role is forced at boot"
mkdir -p /data/adb/usb_role_switch
chmod 700 /data/adb/usb_role_switch
[ -f /data/adb/usb_role_switch/usb-role.log ] || : > /data/adb/usb_role_switch/usb-role.log
chmod 600 /data/adb/usb_role_switch/usb-role.log
chmod 755 "$MODPATH/bin/usb-role.sh" 2>/dev/null
chmod 755 "$MODPATH/bin/usb-power.sh" 2>/dev/null
chmod 755 "$MODPATH/service.sh" 2>/dev/null
chmod 755 "$MODPATH/action.sh" 2>/dev/null

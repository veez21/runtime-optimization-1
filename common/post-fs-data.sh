#!/system/bin/sh
# Please don't hardcode /magisk/modname/... ; instead, please use $MODDIR/...
# This will make your scripts compatible even if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in post-fs-data mode
# More info in the main Magisk thread

grep_prop() {
  REGEX="s/^$1=//p"
  shift
  FILES=$@
  if [ -z "$FILES" ]; then
    FILES='/system/build.prop'
  fi
  cat $FILES 2>/dev/null | sed -n "$REGEX" | head -n 1
}

API=$(grep_prop ro.build.version.sdk)
ram=$(/data/magisk/busybox free -m | grep 'Mem:' | awk '{print $2}')
if [ $API -ge 25 ]; then
  resetprop pm.dexopt.bg-dexopt everything
  if [ $ram -le 1024 ]; then
    resetprop dalvik.vm.dex2oat-swap true
  else
    resetprop dalvik.vm.dex2oat-swap false
  fi
fi

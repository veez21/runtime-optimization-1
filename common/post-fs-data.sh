#!/system/bin/sh
# Please don't hardcode /magisk/modname/... ; instead, please use $MODDIR/...
# This will make your scripts compatible even if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in post-fs-data mode
# More info in the main Magisk thread

grep_prop() {
  _prop=$(grep "$1=" $2)
  echo ${_prop#*=}
  unset _prop
}

ver=$(grep_prop version $MODDIR/module.prop)

log_print() {
  LOGFILE=/cache/magisk.log
  echo "ART Optimization${ver}: $@"
  echo "ART Optimization${ver}: $@" >> $LOGFILE
  log -p i -t "ART Optimizer${ver}" "$@"
}

API=$(grep_prop ro.build.version.sdk /system/build.prop)
ram=$(/data/magisk/busybox free -m | grep 'Mem:' | awk '{print $2}')
filter=$(grep_prop dalvik.vm.image-dex2oat-filter $MODDIR/system.prop)

log_print "Compiler Filter set to: $filter"
log_print "ROM: $(grep_prop ro.build.display.id)"
log_print "API: $API"
log_print "RAM: $ram"

for i in $(cat $MODDIR/system.prop | grep "[a-zA-Z0-9]=[a-zA-Z0-9]"); do
  echo $i | grep "#" >dev/null 2>dev/null || log_print "${i#*=} -> ${i%=*}"
done

if [ $API -ge 25 ]; then
  resetprop pm.dexopt.bg-dexopt $filter
  log_print "pm.dexopt.bg-dexopt -> $filter"
  if [ $ram -le 1024 ]; then
    resetprop dalvik.vm.dex2oat-swap true
	log_print "dalvik.vm.dex2oat-swap -> true"
	resetprop dalvik.vm.heaptargetutilization 0.9
	log_print "dalvik.vm.heaptargetutilization -> 0.9"
  else
    resetprop dalvik.vm.dex2oat-swap false
	log_print "dalvik.vm.dex2oat-swap -> false"
	resetprop dalvik.vm.heaptargetutilization 0.75
	log_print "dalvik.vm.heaptargetutilization -> 0.75"
  fi
fi

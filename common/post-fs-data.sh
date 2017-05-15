#!/system/bin/sh
# Please don't hardcode /magisk/modname/... ; instead, please use $MODDIR/...
# This will make your scripts compatible even if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in post-fs-data mode
# More info in the main Magisk thread

grep_prop() {
  _prop=$(grep "$1=" $2)
  [ $? -gt 0 ] && return 1
  echo ${_prop#*=}
  unset _prop
}

# Get version
ver=$(grep_prop version $MODDIR/module.prop)
# Determine if logging is on
[ -n $1 ] && [ $1 == "false" ] && LOG=$1 || LOG=true

log_print() {
  if ($LOG); then
    echo "ART Optimization ${ver}: $@"
    echo "ART Optimization ${ver}: $@" >> /cache/magisk.log
    log -p i -t "ART Optimizer ${ver}" "$@"
  fi
}

set_prop() {
  [ -n "$3" ] && prop=$3 || prop=$MODDIR/system.prop 
  if (grep -q "$1=" $prop); then
    sed -i "s/${1}=.*/${1}=${2}/g" $prop
  else
    echo "${1}=${2}" >> $prop
    log_print "${1} -> ${2}"
  fi
  test -f /system/bin/setprop && setprop $1 $2
  resetprop $1 $2
}

# List props to be removed
to_be_removed="
pm.dexopt.bg-dexopt
dalvik.vm.dex2oat-swap
"

# Get Info
API=$(grep_prop ro.build.version.sdk /system/build.prop) || API="error"
ram=$(/data/magisk/busybox free -m | grep 'Mem:' | awk '{print $2}')
filter=$(grep_prop dalvik.vm.image-dex2oat-filter $MODDIR/system.prop)
rom=$(grep_prop ro.build.display.id /system/build.prop) || rom="error"

# Log Info
log_print "Compiler Filter set to: $filter"
log_print "ROM: $rom"
log_print "API: $API"
log_print "RAM: $ram"

# Remove conditional properties
log_print "Removing conditional properties from system.prop"
for i in "$to_be_removed"; do
  if (grep -q "$i=" $MODDIR/system.prop); then
    sed -i 's/${i}=.*//g' $MODDIR/system.prop
    log_print "${i}: removed"
  fi
done

# Set properties
log_print "Setting properties through resetprop"
for i in $(cat $MODDIR/system.prop | grep "[a-zA-Z0-9]=[a-zA-Z0-9]" | sed 's/ /_/g'); do
  [[ $(echo $i | grep "#_") ]] || log_print "${i%=*} -> ${i#*=}"
done

set_prop dalvik.vm.dex2oat-filter $filter
if [ $ram -le 1024 ]; then
  set_prop dalvik.vm.heaptargetutilization 0.9
else
  set_prop dalvik.vm.heaptargetutilization 0.75
fi
if [ $API -ge 25 ] || [ $API == "error" ]; then
  set_prop pm.dexopt.bg-dexopt $filter
  if [ $ram -le 1024 ]; then
    set_prop dalvik.vm.dex2oat-swap true
  else
    set_prop dalvik.vm.dex2oat-swap false
  fi
fi

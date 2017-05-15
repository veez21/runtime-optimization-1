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
[ -n $1 ] && [ $1 == "false" ] && service=$1 || service=true

log_print() {
  if ($service); then
    LOGFILE=/cache/magisk.log
    echo "ART Optimization ${ver}: $@"
    echo "ART Optimization ${ver}: $@" >> $LOGFILE
    log -p i -t "ART Optimizer ${ver}" "$@"
  fi
}

set_prop() {
  [ -n "$3" ] && prop=$3 || prop=$MODDIR/system.prop 
  if (grep -q "$1=" $prop); then
    sed -i "s/${1}=.*/${1}=${2}/g" $prop
  else
    echo "${1}=${2}" >> $prop
  fi
  test -f /system/bin/setprop && setprop $1 $2
  resetprop $1 $2
  log_print "${1} -> ${2}"
}

API=$(grep_prop ro.build.version.sdk /system/build.prop)
ram=$(/data/magisk/busybox free -m | grep 'Mem:' | awk '{print $2}')
filter=$(grep_prop dalvik.vm.image-dex2oat-filter $MODDIR/system.prop)

log_print "Compiler Filter set to: $filter"
log_print "ROM: $(grep_prop ro.build.display.id /system/build.prop)"
log_print "API: $API"
log_print "RAM: $ram"

for i in $(cat $MODDIR/system.prop | grep "[a-zA-Z0-9]=[a-zA-Z0-9]" | sed 's/ /_/g'); do
  [[ $(echo $i | grep "#_" >dev/null 2>dev/null) ]] || log_print "${i%=*} -> ${i#*=}"
done

if [ $ram -le 1024 ]; then
  set_prop dalvik.vm.heaptargetutilization 0.9
else
  set_prop dalvik.vm.heaptargetutilization 0.75
fi

if [ $API -ge 25 ]; then
  set_prop pm.dexopt.bg-dexopt $filter
  if [ $ram -le 1024 ]; then
    set_prop dalvik.vm.dex2oat-swap true
  else
    set_prop dalvik.vm.dex2oat-swap false
  fi
fi

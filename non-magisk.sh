#!/system/bin/sh
# Android Runtime Optimization v1.2 by veez21
# Non-Magisk Module
set -x 2>/cache/art-opt.log
# Put this in:
# - /su/su.d - preferred
# - /system/su.d - preferred
# - /system/etc/init.d ???

## You can edit the 'filter' variable if you like ;)
## More information in the XDA thread
filter=speed
## More information in the XDA thread

## Don't touch the stuff below :P
set_prop() {
  [ -n "$3" ] && prop=$3 || prop=/system/build.prop 
  if (grep -q "$1=" $prop); then
    sed -i "s/${1}=.*/${1}=${2}/g" $prop
  else
    echo "${1}=${2}" >> $prop
  fi
  test -f /system/bin/setprop && setprop $1 $2
}

to_be_removed="
pm.dexopt.bg-dexopt
dalvik.vm.dex2oat-swap
dalvik.vm.dex2oat-threads
dalvik.vm.boot-dex2oat-threads
"

API=$(cat /system/build.prop 2>/dev/null | sed -n "s/^ro.build.version.sdk=//p" | head -n 1)
ram=$(busybox free -m | grep 'Mem:' | awk '{print $2}')
[ $? -ne 0 ] && ram=$(($(cat /proc/meminfo | grep 'MemTotal:' | awk '{print $2}')/1024))

mount -o remount,rw / 2>/dev/null
mount -o remount,rw /system 2>/dev/null
mount -o rw,remount / 2>/dev/null
mount -o rw,remount /system 2>/dev/null

for i in $to_be_removed; do
  if (grep -q "$i=" /system/build.prop); then
    sed -i 's/${i}=.*//g' /system/build.prop
  fi
done

set_prop dalvik.vm.image-dex2oat-filter $filter
set_prop dalvik.vm.dex2oat-filter speed
set_prop dalvik.vm.check-dex-sum false
set_prop dalvik.vm.checkjni false
set_prop dalvik.vm.execution-mode int:jit
set_prop dalvik.vm.dex2oat-thread_count 4
set_prop dalvik.vm.dexopt-flags v=a,o=v
if [ $API -ge 25 ]; then
  set_prop pm.dexopt.bg-dexopt $filter
  if [ $ram -le 1024 ]; then
    set_prop dalvik.vm.dex2oat-swap true
	set_prop dalvik.vm.heaptargetutilization 0.9
  else
    set_prop dalvik.vm.dex2oat-swap false
	set_prop dalvik.vm.heaptargetutilization 0.75
  fi
elif [ $API -ge 23 ]; then
  set_prop dalvik.vm.dex2oat-threads 4
fi

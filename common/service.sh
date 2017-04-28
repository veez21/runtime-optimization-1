#!/system/bin/sh
# Please don't hardcode /magisk/modname/... ; instead, please use $MODDIR/...
# This will make your scripts compatible even if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in late_start service mode
# More info in the main Magisk thread

set_prop() {
  setprop $1 $2
  resetprop $1 $2
}

get_file_prop() {
  _prop=$(grep "$1=" $2)
  echo ${_prop#*=}
  unset _prop
}

## You can edit this if you like ;)
## More information in the XDA thread
set_prop dalvik.vm.image-dex2oat-filter $(get_file_prop dalvik.vm.image-dex2oat-filter $MODDIR/system.prop)
## You can edit this if you like ;)

## Don't touch me :P
set_prop dalvik.vm.dex2oat-filter speed
## Don't touch me :P

##########################################################################################
#
# Magisk
# by topjohnwu
# 
# This is a template zip for developers
#
##########################################################################################
##########################################################################################
# 
# Instructions:
# 
# 1. Place your files into system folder (delete the placeholder file)
# 2. Fill in your module's info into module.prop
# 3. Configure the settings in this file (common/config.sh)
# 4. For advanced features, add shell commands into the script files under common:
#    post-fs-data.sh, service.sh
# 5. For changing props, add your additional/modified props into common/system.prop
# 
##########################################################################################

##########################################################################################
# Defines
##########################################################################################

# NOTE: This part has to be adjusted to fit your own needs

# This will be the folder name under /magisk
# This should also be the same as the id in your module.prop to prevent confusion
MODID=runtime-optimization

# Set to true if you need to enable Magic Mount
# Most mods would like it to be enabled
AUTOMOUNT=true

# Set to true if you need to load system.prop
PROPFILE=true

# Set to true if you need post-fs-data script
POSTFSDATA=true

# Set to true if you need late_start service script
LATESTARTSERVICE=true

##########################################################################################
# Installation Message
##########################################################################################

# Set what you want to show when installing your mod

print_modname() {
  ui_print "******************************"
  ui_print " Android Runtime Optimization "
  ui_print "******************************"
}

##########################################################################################
# Replace list
##########################################################################################

# List all directories you want to directly replace in the system
# By default Magisk will merge your files with the original system
# Directories listed here however, will be directly mounted to the correspond directory in the system

# You don't need to remove the example below, these values will be overwritten by your own list
# This is an example
REPLACE="
/system/app/Youtube
/system/priv-app/SystemUI
/system/priv-app/Settings
/system/framework
"

# Construct your own list here, it will overwrite the example
# !DO NOT! remove this if you don't need to replace anything, leave it empty as it is now
REPLACE="
"

##########################################################################################
# Permissions
##########################################################################################

# NOTE: This part has to be adjusted to fit your own needs

set_permissions() {
  # Default permissions, don't remove them
  set_perm_recursive  $MODPATH  0  0  0755  0644

  # Only some special files require specific permissions
  # The default permissions should be good enough for most cases

  # Some templates if you have no idea what to do:

  # set_perm_recursive  <dirname>                <owner> <group> <dirpermission> <filepermission> <contexts> (default: u:object_r:system_file:s0)
  # set_perm_recursive  $MODPATH/system/lib       0       0       0755            0644

  # set_perm  <filename>                         <owner> <group> <permission> <contexts> (default: u:object_r:system_file:s0)
  # set_perm  $MODPATH/system/bin/app_process32   0       2000    0755         u:object_r:zygote_exec:s0
  # set_perm  $MODPATH/system/bin/dex2oat         0       2000    0755         u:object_r:dex2oat_exec:s0
  # set_perm  $MODPATH/system/lib/libart.so       0       0       0644
  set_perm $MODPATH/system/bin/art_magisk 0 0 0777
}

get_file_prop() { 
  _prop=$(grep "$1=" $2)
  [ $? -gt 0 ] && return 1
  echo ${_prop#*=}
  unset _prop
}

set_prop() {
  [ -n "$3" ] && prop=$3 || prop=$MODDIR/system.prop 
  if (grep -q "$1=" $prop); then
    sed -i "s/${1}=.*/${1}=${2}/g" $prop
  else
    echo "${1}=${2}" >> $prop
  fi
}

message_wipe() {
ui_print "******************************"
ui_print "*     FOR BEST RESULTS,      *"  
ui_print "*     WIPE DALVIK-CACHE      *"
ui_print "******************************"
}

install_workaround() {
    ui_print "- Finding workaround"
	unzip -o "$ZIP" non-magisk.sh
	[ -f /data/su.img ] && SUIMG=/data/su.img
	[ -z "$SUIMG" ] && [ -f /cache/su.img ] && SUIMG=/cache/su.img
	if [ -n "$SUIMG" ] && [ -f "$SUIMG" ]; then
	  ui_print "- Systemless SuperSU Detected"
      mount_image $SUIMG /su
	  if ! is_mounted /su; then
        ui_print "! $SUIMG mount failed... abort"
	    if [ -d /data/data/eu.chainfire.supersu ]; then
	      ui_print "- Force install to /system/su.d"
		  mkdir -p /system/su.d
		  cp -f $INSTALLER/non-magisk.sh /system/su.d/art-opt.sh
		  chmod 755 /system/su.d/art-opt.sh
		  chown 0.0 /system/su.d/art-opt.sh
		  if [ -d /system/etc/init.d ]; then
   		    ui_print "- Init.d Directory found"
		    ui_print "- Linking script to /system/etc/init.d"
		    ln -s /system/su.d/art-opt.sh /system/etc/init.d
		  fi
		  ui_print "- Executing script"
		  /system/su.d/art-opt.sh
		  ui_print "- Done"
		  exit
		fi
	  else
	    mkdir -p /su/su.d
		if [ -f /su/su.d/art-opt.sh ]; then
		  ui_print "- Detecting previous compiler filter"
		  prev=$(get_file_prop filter /su/su.d/art-opt.sh)
		  if [ $? -gt 0 ]; then
		    ui_print "- --compiler-filter: speed"
			prev=speed
		  else
		    ui_print "- --compiler-filter: $prev"
			UPDATE=true
	      fi
		fi
		cp -f $INSTALLER/non-magisk.sh /su/su.d/art-opt.sh
		chmod 755 /su/su.d/art-opt.sh
		chown 0.0 /su/su.d/art-opt.sh
		set_prop filter $prev /su/su.d/art-opt.sh
		ui_print "- Executing script"
		/su/su.d/art-opt.sh
		ui_print "- Done"
		message_wipe
		exit
      fi
	else
      if [ -d /data/data/eu.chainfire.supersu ] && [ -f /system/xbin/su ]; then
        ui_print "- System SuperSU Detected"
        ui_print "- Installing in /system/su.d"
		if [ -f /system/su.d/art-opt.sh ]; then
		  ui_print "- Detecting previous compiler filter"
		  prev=$(get_file_prop filter /su/su.d/art-opt.sh)
		  if [ $? -gt 0 ]; then
		    ui_print "- --compiler-filter: speed"
			prev=speed
		  else
		    ui_print "- --compiler-filter: $prev"
			UPDATE=true
	      fi
		fi
        mkdir -p /system/su.d
        cp -f $INSTALLER/non-magisk.sh /system/su.d/art-opt.sh
        chmod 755 /system/su.d/art-opt.sh
        chown 0.0 /system/su.d/art-opt.sh
		set_prop filter $prev /system/su.d/art-opt.sh
        if [ -d /system/etc/init.d ]; then
          ui_print "- Init.d Directory found"
          ui_print "- Linking script to /system/etc/init.d"
          ln -s /system/su.d/art-opt.sh /system/etc/init.d
        fi
		ui_print "- Executing script"
        /system/su.d/art-opt.sh
		ui_print "- Done"
		message_wipe
		exit
      fi	
    fi
	if [ -d /system/etc/init.d ]; then
	  ui_print "- Init.d Detected"
	  cp -f $INSTALLER/non-magisk.sh /system/etc/init.d/art-opt.sh 
	  chmod 755 /system/etc/init.d/art-opt.sh
	  chown 0.0 /system/etc/init.d/art-opt.sh
      if [ -f /system/su.d/art-opt.sh ]; then
		ui_print "- Detecting previous compiler filter"
		prev=$(get_file_prop filter /su/su.d/art-opt.sh)
		if [ $? -gt 0 ]; then
		  ui_print "- --compiler-filter: speed"
		  prev=speed
		else
		  ui_print "- --compiler-filter: $prev"
		  UPDATE=true
	    fi
	  fi
	  set_prop filter $prev /system/etc/init.d/art-opt.sh
	  ui_print "- Executing script"
	  /system/etc/init.d/art-opt.sh
	  ui_print "- Done"
	  message_wipe
	  exit
	fi
	ui_print "! Nothing found... abort!"
    exit 1
}

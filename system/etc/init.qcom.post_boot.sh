#!/system/bin/sh
# Copyright (c) 2012-2013, 2016, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

target=`getprop ro.board.platform`
project=`getprop ro.boot.project_name`

function configure_memory_parameters() {
    # Set Memory paremeters.
    #
    # Set per_process_reclaim tuning parameters
    # 2GB 64-bit will have aggressive settings when compared to 1GB 32-bit
    # 1GB and less will use vmpressure range 50-70, 2GB will use 10-70
    # 1GB and less will use 512 pages swap size, 2GB will use 1024
    #
    # Set Low memory killer minfree parameters
    # 32 bit all memory configurations will use 15K series
    # 64 bit up to 2GB with use 14K, and above 2GB will use 18K
    #
    # Set ALMK parameters (usually above the highest minfree values)
    # 32 bit will have 53K & 64 bit will have 81K
    #
    # Set ZCache parameters
    # max_pool_percent is the percentage of memory that the compressed pool
    # can occupy.
    # clear_percent is the percentage of memory at which zcache starts
    # evicting compressed pages. This should be slighlty above adj0 value.
    # clear_percent = (adj0 * 100 / avalible memory in pages)+1
    #
    arch_type=`uname -m`
    MemTotalStr=`cat /proc/meminfo | grep MemTotal`
    MemTotal=${MemTotalStr:16:8}
    MemTotalPg=$((MemTotal / 4))
    adjZeroMinFree=18432
    # Read adj series and set adj threshold for PPR and ALMK.
    # This is required since adj values change from framework to framework.
    adj_series=`cat /sys/module/lowmemorykiller/parameters/adj`
    adj_1="${adj_series#*,}"
    set_almk_ppr_adj="${adj_1%%,*}"
    # PPR and ALMK should not act on HOME adj and below.
    # Normalized ADJ for HOME is 6. Hence multiply by 6
    # ADJ score represented as INT in LMK params, actual score can be in decimal
    # Hence add 6 considering a worst case of 0.9 conversion to INT (0.9*6).
    set_almk_ppr_adj=$(((set_almk_ppr_adj * 6) + 6))
    echo $set_almk_ppr_adj > /sys/module/lowmemorykiller/parameters/adj_max_shift
    echo $set_almk_ppr_adj > /sys/module/process_reclaim/parameters/min_score_adj
    echo 1 > /sys/module/process_reclaim/parameters/enable_process_reclaim
    echo 70 > /sys/module/process_reclaim/parameters/pressure_max
    echo 30 > /sys/module/process_reclaim/parameters/swap_opt_eff
    echo 1 > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
    if [ "$arch_type" == "aarch64" ] && [ $MemTotal -gt 2097152 ]; then
        echo 10 > /sys/module/process_reclaim/parameters/pressure_min
        echo 1024 > /sys/module/process_reclaim/parameters/per_swap_size
        echo "18432,23040,27648,32256,55296,80640" > /sys/module/lowmemorykiller/parameters/minfree
        echo 81250 > /sys/module/lowmemorykiller/parameters/vmpressure_file_min
        adjZeroMinFree=18432
    elif [ "$arch_type" == "aarch64" ] && [ $MemTotal -gt 1048576 ]; then
        echo 10 > /sys/module/process_reclaim/parameters/pressure_min
        echo 1024 > /sys/module/process_reclaim/parameters/per_swap_size
        echo "14746,18432,22118,25805,40000,55000" > /sys/module/lowmemorykiller/parameters/minfree
        echo 81250 > /sys/module/lowmemorykiller/parameters/vmpressure_file_min
        adjZeroMinFree=14746
    elif [ "$arch_type" == "aarch64" ]; then
        echo 50 > /sys/module/process_reclaim/parameters/pressure_min
        echo 512 > /sys/module/process_reclaim/parameters/per_swap_size
        echo "14746,18432,22118,25805,40000,55000" > /sys/module/lowmemorykiller/parameters/minfree
        echo 81250 > /sys/module/lowmemorykiller/parameters/vmpressure_file_min
        adjZeroMinFree=14746
    else
        echo 50 > /sys/module/process_reclaim/parameters/pressure_min
        echo 512 > /sys/module/process_reclaim/parameters/per_swap_size
        echo "15360,19200,23040,26880,34415,43737" > /sys/module/lowmemorykiller/parameters/minfree
        echo 53059 > /sys/module/lowmemorykiller/parameters/vmpressure_file_min
        adjZeroMinFree=15360
    fi
    clearPercent=$((((adjZeroMinFree * 100) / MemTotalPg) + 1))
    echo $clearPercent > /sys/module/zcache/parameters/clear_percent
    echo 30 >  /sys/module/zcache/parameters/max_pool_percent

    # Zram disk - 512MB size
    zram_enable=`getprop ro.config.zram`
    if [ "$zram_enable" == "true" ]; then
        echo 536870912 > /sys/block/zram0/disksize
        mkswap /dev/block/zram0
        swapon /dev/block/zram0 -p 32758
    fi

    SWAP_ENABLE_THRESHOLD=1048576
    swap_enable=`getprop ro.config.swap`

    if [ -f /sys/devices/soc0/soc_id ]; then
        soc_id=`cat /sys/devices/soc0/soc_id`
    else
        soc_id=`cat /sys/devices/system/soc/soc0/id`
    fi

    # Enable swap initially only for 1 GB targets
    if [ "$MemTotal" -le "$SWAP_ENABLE_THRESHOLD" ] && [ "$swap_enable" == "true" ]; then
        # Static swiftness
        echo 1 > /proc/sys/vm/swap_ratio_enable
        echo 70 > /proc/sys/vm/swap_ratio

        # Swap disk - 200MB size
        if [ ! -f /data/system/swap/swapfile ]; then
            dd if=/dev/zero of=/data/system/swap/swapfile bs=1m count=200
        fi
        mkswap /data/system/swap/swapfile
        swapon /data/system/swap/swapfile -p 32758
    fi
}

case "$target" in
    "msm8996")
        # disable thermal bcl hotplug to switch governor
        echo 0 > /sys/module/msm_thermal/core_control/enabled
        echo -n disable > /sys/devices/soc/soc:qcom,bcl/mode
        bcl_hotplug_mask=`cat /sys/devices/soc/soc:qcom,bcl/hotplug_mask`
        echo 0 > /sys/devices/soc/soc:qcom,bcl/hotplug_mask
        bcl_soc_hotplug_mask=`cat /sys/devices/soc/soc:qcom,bcl/hotplug_soc_mask`
        echo 0 > /sys/devices/soc/soc:qcom,bcl/hotplug_soc_mask
        echo -n enable > /sys/devices/soc/soc:qcom,bcl/mode

        # Enable Adaptive LMK
        # echo 1 > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
		# echo "18432,23040,27648,51256,150296,200640" > /sys/module/lowmemorykiller/parameters/minfree
        # echo 202640 > /sys/module/lowmemorykiller/parameters/vmpressure_file_min
        # configure governor settings for little cluster
        echo "interactive" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
        echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_sched_load
        echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_migration_notif
        echo "20000 1113600:30000 1478400:50000" > /sys/devices/system/cpu/cpu0/cpufreq/interactive/above_hispeed_delay
        echo 45 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/go_hispeed_load
        echo 10000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_rate
        echo 20000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_slack
        echo 844800 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq
        echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
        echo "70 1113600:85 1478400:95" > /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads
        echo 20000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/min_sample_time
        echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/max_freq_hysteresis
        echo 300000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
        # echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/ignore_hispeed_on_notif
        # online CPU2
        echo 1 > /sys/devices/system/cpu/cpu2/online
        # configure governor settings for big cluster
        echo "interactive" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor
        echo 1 > /sys/devices/system/cpu/cpu2/cpufreq/interactive/use_sched_load
        echo 1 > /sys/devices/system/cpu/cpu2/cpufreq/interactive/use_migration_notif
        echo "20000 1248000:30000 1632000:60000" > /sys/devices/system/cpu/cpu2/cpufreq/interactive/above_hispeed_delay
        echo 55 > /sys/devices/system/cpu/cpu2/cpufreq/interactive/go_hispeed_load
        echo 10000 > /sys/devices/system/cpu/cpu2/cpufreq/interactive/timer_rate
        echo 20000 > /sys/devices/system/cpu/cpu2/cpufreq/interactive/timer_slack
        echo 940800 > /sys/devices/system/cpu/cpu2/cpufreq/interactive/hispeed_freq
        echo 1 > /sys/devices/system/cpu/cpu2/cpufreq/interactive/io_is_busy
        echo "75 1248000:90 1632000:99 1996800:100" > /sys/devices/system/cpu/cpu2/cpufreq/interactive/target_loads
        echo 20000 > /sys/devices/system/cpu/cpu2/cpufreq/interactive/min_sample_time
        echo 0 > /sys/devices/system/cpu/cpu2/cpufreq/interactive/max_freq_hysteresis
        echo 300000 > /sys/devices/system/cpu/cpu2/cpufreq/scaling_min_freq
        # echo 1 > /sys/devices/system/cpu/cpu2/cpufreq/interactive/ignore_hispeed_on_notif
        # re-enable thermal and BCL hotplug
        echo 1 > /sys/module/msm_thermal/core_control/enabled
        echo -n disable > /sys/devices/soc/soc:qcom,bcl/mode
        echo $bcl_hotplug_mask > /sys/devices/soc/soc:qcom,bcl/hotplug_mask
        echo $bcl_soc_hotplug_mask > /sys/devices/soc/soc:qcom,bcl/hotplug_soc_mask
        echo -n enable > /sys/devices/soc/soc:qcom,bcl/mode
        # Setting b.L scheduler parameters
        echo 0 > /proc/sys/kernel/sched_boost
        echo 1 > /proc/sys/kernel/sched_migration_fixup
        echo 45 > /proc/sys/kernel/sched_downmigrate
        echo 45 > /proc/sys/kernel/sched_upmigrate
        echo 400000 > /proc/sys/kernel/sched_freq_inc_notify
        echo 400000 > /proc/sys/kernel/sched_freq_dec_notify
        echo 3 > /proc/sys/kernel/sched_spill_nr_run
        echo 100 > /proc/sys/kernel/sched_init_task_load
        # Enable bus-dcvs
        for cpubw in /sys/class/devfreq/*qcom,cpubw*
        do
            echo "bw_hwmon" > $cpubw/governor
            echo 50 > $cpubw/polling_interval
            echo 1525 > $cpubw/min_freq
            echo "1525 5195 11863 13763" > $cpubw/bw_hwmon/mbps_zones
            echo 4 > $cpubw/bw_hwmon/sample_ms
            echo 34 > $cpubw/bw_hwmon/io_percent
            echo 20 > $cpubw/bw_hwmon/hist_memory
            echo 10 > $cpubw/bw_hwmon/hyst_length
            echo 0 > $cpubw/bw_hwmon/low_power_ceil_mbps
            echo 34 > $cpubw/bw_hwmon/low_power_io_percent
            echo 20 > $cpubw/bw_hwmon/low_power_delay
            echo 0 > $cpubw/bw_hwmon/guard_band_mbps
            echo 250 > $cpubw/bw_hwmon/up_scale
            echo 1600 > $cpubw/bw_hwmon/idle_mbps
        done

        for memlat in /sys/class/devfreq/*qcom,memlat-cpu*
        do
            echo "mem_latency" > $memlat/governor
            echo 10 > $memlat/polling_interval
        done
        echo "cpufreq" > /sys/class/devfreq/soc:qcom,mincpubw/governor

	soc_revision=`cat /sys/devices/soc0/revision`
	if [ "$soc_revision" == "2.0" ]; then
		#Disable suspend for v2.0
		echo pwr_dbg > /sys/power/wake_lock
	elif [ "$soc_revision" == "2.1" ]; then
		# Enable C4.D4.E4.M3 LPM modes
		# Disable D3 state
		echo 0 > /sys/module/lpm_levels/system/pwr/pwr-l2-gdhs/idle_enabled
		echo 0 > /sys/module/lpm_levels/system/perf/perf-l2-gdhs/idle_enabled
		# Disable DEF-FPC mode
		echo N > /sys/module/lpm_levels/system/pwr/cpu0/fpc-def/idle_enabled
		echo N > /sys/module/lpm_levels/system/pwr/cpu1/fpc-def/idle_enabled
		echo N > /sys/module/lpm_levels/system/perf/cpu2/fpc-def/idle_enabled
		echo N > /sys/module/lpm_levels/system/perf/cpu3/fpc-def/idle_enabled
	else
		# Enable all LPMs by default
		# This will enable C4, D4, D3, E4 and M3 LPMs
		echo N > /sys/module/lpm_levels/parameters/sleep_disabled
	fi
	echo N > /sys/module/lpm_levels/parameters/sleep_disabled
        # Starting io prefetcher service
        start iop

	if [ -f "/defrag_aging.ko" ]; then
		insmod /defrag_aging.ko
	else
		insmod /system/lib/modules/defrag.ko
	fi
        sleep 1
        lsmod | grep defrag
        if [ $? != 0 ]; then
            echo 1 > /sys/module/defrag_helper/parameters/disable
        fi
    ;;
esac

case "$project" in
    "15811")
        # input boost configuration
        echo "0:1286400 2:1286400" > /sys/module/cpu_boost/parameters/input_boost_freq
        echo 40 > /sys/module/cpu_boost/parameters/input_boost_ms
    ;;
esac

case "$project" in
    "15801")
        # input boost configuration
        echo "0:1324800 2:1324800" > /sys/module/cpu_boost/parameters/input_boost_freq
        echo 40 > /sys/module/cpu_boost/parameters/input_boost_ms
    ;;
esac

case "$target" in
    "qsd8650a_st1x")
        mount -t debugfs none /sys/kernel/debug
    ;;
esac

emmc_boot=`getprop ro.boot.emmc`
case "$emmc_boot"
    in "true")
        chown -h system /sys/devices/platform/rs300000a7.65536/force_sync
        chown -h system /sys/devices/platform/rs300000a7.65536/sync_sts
        chown -h system /sys/devices/platform/rs300100a7.65536/force_sync
        chown -h system /sys/devices/platform/rs300100a7.65536/sync_sts
    ;;
esac

case "$target" in
    "msm8960" | "msm8660" | "msm7630_surf")
        echo 10 > /sys/devices/platform/msm_sdcc.3/idle_timeout
        ;;
    "msm7627a")
        echo 10 > /sys/devices/platform/msm_sdcc.1/idle_timeout
        ;;
esac

# Post-setup services
case "$target" in
    "msm8994" | "msm8992" | "msm8996" | "msm8998")
        setprop sys.post_boot.parsed 1
    ;;
    "msm7627a")
        if [ -f /sys/devices/soc0/soc_id ]; then
            soc_id=`cat /sys/devices/soc0/soc_id`
        else
            soc_id=`cat /sys/devices/system/soc/soc0/id`
        fi
        case "$soc_id" in
            "127" | "128" | "129")
                start mpdecision
        ;;
        esac
    ;;
esac

# Install AdrenoTest.apk if not already installed
if [ -f /data/prebuilt/AdrenoTest.apk ]; then
    if [ ! -d /data/data/com.qualcomm.adrenotest ]; then
        pm install /data/prebuilt/AdrenoTest.apk
    fi
fi

# Install SWE_Browser.apk if not already installed
if [ -f /data/prebuilt/SWE_AndroidBrowser.apk ]; then
    if [ ! -d /data/data/com.android.swe.browser ]; then
        pm install /data/prebuilt/SWE_AndroidBrowser.apk
    fi
fi

# Let kernel know our image version/variant/crm_version
if [ -f /sys/devices/soc0/select_image ]; then
    image_version="10:"
    image_version+=`getprop ro.build.id`
    image_version+=":"
    image_version+=`getprop ro.build.version.incremental`
    image_variant=`getprop ro.product.name`
    image_variant+="-"
    image_variant+=`getprop ro.build.type`
    oem_version=`getprop ro.build.version.codename`
    echo 10 > /sys/devices/soc0/select_image
    echo $image_version > /sys/devices/soc0/image_version
    echo $image_variant > /sys/devices/soc0/image_variant
    echo $oem_version > /sys/devices/soc0/image_crm_version
fi

# Change console log level as per console config property
console_config=`getprop persist.console.silent.config`
case "$console_config" in
    "1")
        echo "Enable console config to $console_config"
        echo 0 > /proc/sys/kernel/printk
        ;;
    *)
        echo "Enable console config to $console_config"
        ;;
esac

# More tweaks by WarBeard...
# Disable zRAM and adjust RAM management (lmk parameters)
swapoff /dev/block/zram0
echo 1 > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
echo 81250 > /sys/module/lowmemorykiller/parameters/vmpressure_file_min
echo 51322,69652,89815,135639,155801,183296 > /sys/module/lowmemorykiller/parameters/minfree
echo 0,100,200,300,900,906 > /sys/module/lowmemorykiller/parameters/adj
echo 353 > /sys/module/lowmemorykiller/parameters/adj_max_shift
echo 32 > /sys/module/lowmemorykiller/parameters/cost
echo 1 > /sys/module/lowmemorykiller/parameters/debug_level
echo 1 > /sys/module/lowmemorykiller/parameters/lmk_fast_run
# Set input boost parameters
echo "0:844800 1:844800 2:729600 3:729600" > /sys/module/cpu_boost/parameters/input_boost_freq
echo 40 > /sys/module/cpu_boost/parameters/input_boost_ms
# Set other VM parameters
echo 1 > /proc/sys/vm/swappiness
echo 20 > /proc/sys/vm/dirty_background_ratio
echo 40 > /proc/sys/vm/dirty_ratio
echo 100 > /proc/sys/vm/vfs_cache_pressure
echo 1 > /proc/sys/vm/oom_dump_tasks
echo 0 > /proc/sys/vm/oom_kill_allocating_task
echo 50 > /proc/sys/vm/overcommit_ratio
echo 0 > /proc/sys/vm/panic_on_oom
echo 100 > /proc/sys/vm/swap_ratio
echo 200 > /proc/sys/vm/dirty_expire_centisecs
echo 500 > /proc/sys/vm/dirty_writeback_centisecs
# Tune CFQ scheduler for flash storage devices
# Tune CFQ sched - mmcblkk0 (externalSD)
chmod 777 /sys/block/mmcblk0/queue/iosched/back_seek_max
echo 16 > /sys/block/mmcblk0/queue/iosched/back_seek_max
chmod 644 /sys/block/mmcblk0/queue/iosched/back_seek_max
chmod 777 /sys/block/mmcblk0/queue/iosched/slice_idle
echo 0 > /sys/block/mmcblk0/queue/iosched/slice_idle
chmod 644 /sys/block/mmcblk0/queue/iosched/slice_idle
chmod 777 /sys/block/mmcblk0/queue/iosched/quantum
echo 32 > /sys/block/mmcblk0/queue/iosched/quantum
chmod 644 /sys/block/mmcblk0/queue/iosched/quantum
chmod 777 /sys/block/mmcblk0/queue/iosched/group_idle
echo 1 > /sys/block/mmcblk0/queue/iosched/group_idle
chmod 644 /sys/block/mmcblk0/queue/iosched/group_idle
chmod 777 /sys/block/mmcblk0/queue/iosched/low_latency
echo 1 > /sys/block/mmcblk0/queue/iosched/low_latency
chmod 644 /sys/block/mmcblk0/queue/iosched/low_latency
# Tune CFQ sched - sda (device)
chmod 777 /sys/block/sda/queue/iosched/back_seek_max
echo 16 > /sys/block/sda/queue/iosched/back_seek_max
chmod 644 /sys/block/sda/queue/iosched/back_seek_max
chmod 777 /sys/block/sda/queue/iosched/slice_idle
echo 0 > /sys/block/sda/queue/iosched/slice_idle
chmod 644 /sys/block/sda/queue/iosched/slice_idle
chmod 777 /sys/block/sda/queue/iosched/quantum
echo 32 > /sys/block/sda/queue/iosched/quantum
chmod 644 /sys/block/sda/queue/iosched/quantum
chmod 777 /sys/block/sda/queue/iosched/group_idle
echo 1 > /sys/block/sda/queue/iosched/group_idle
chmod 644 /sys/block/sda/queue/iosched/group_idle
chmod 777 /sys/block/sda/queue/iosched/low_latency
echo 1 > /sys/block/sda/queue/iosched/low_latency
chmod 644 /sys/block/sda/queue/iosched/low_latency
# Tune CFQ sched - sdb (device)
chmod 777 /sys/block/sdb/queue/iosched/back_seek_max
echo 16 > /sys/block/sdb/queue/iosched/back_seek_max
chmod 644 /sys/block/sdb/queue/iosched/back_seek_max
chmod 777 /sys/block/sdb/queue/iosched/slice_idle
echo 0 > /sys/block/sdb/queue/iosched/slice_idle
chmod 644 /sys/block/sdb/queue/iosched/slice_idle
chmod 777 /sys/block/sdb/queue/iosched/quantum
echo 32 > /sys/block/sdb/queue/iosched/quantum
chmod 644 /sys/block/sdb/queue/iosched/quantum
chmod 777 /sys/block/sdb/queue/iosched/group_idle
echo 1 > /sys/block/sdb/queue/iosched/group_idle
chmod 644 /sys/block/sdb/queue/iosched/group_idle
chmod 777 /sys/block/sdb/queue/iosched/low_latency
echo 1 > /sys/block/sdb/queue/iosched/low_latency
chmod 644 /sys/block/sdb/queue/iosched/low_latency
# Tune CFQ sched - sdc (device)
chmod 777 /sys/block/sdc/queue/iosched/back_seek_max
echo 16 > /sys/block/sdc/queue/iosched/back_seek_max
chmod 644 /sys/block/sdc/queue/iosched/back_seek_max
chmod 777 /sys/block/sdc/queue/iosched/slice_idle
echo 0 > /sys/block/sdc/queue/iosched/slice_idle
chmod 644 /sys/block/sdc/queue/iosched/slice_idle
chmod 777 /sys/block/sdc/queue/iosched/quantum
echo 32 > /sys/block/sdc/queue/iosched/quantum
chmod 644 /sys/block/sdc/queue/iosched/quantum
chmod 777 /sys/block/sdc/queue/iosched/group_idle
echo 1 > /sys/block/sdc/queue/iosched/group_idle
chmod 644 /sys/block/sdc/queue/iosched/group_idle
chmod 777 /sys/block/sdc/queue/iosched/low_latency
echo 1 > /sys/block/sdc/queue/iosched/low_latency
chmod 644 /sys/block/sdc/queue/iosched/low_latency
# Tune CFQ sched - sdd (device)
chmod 777 /sys/block/sdd/queue/iosched/back_seek_max
echo 16 > /sys/block/sdd/queue/iosched/back_seek_max
chmod 644 /sys/block/sdd/queue/iosched/back_seek_max
chmod 777 /sys/block/sdd/queue/iosched/slice_idle
echo 0 > /sys/block/sdd/queue/iosched/slice_idle
chmod 644 /sys/block/sdd/queue/iosched/slice_idle
chmod 777 /sys/block/sdd/queue/iosched/quantum
echo 32 > /sys/block/sdd/queue/iosched/quantum
chmod 644 /sys/block/sdd/queue/iosched/quantum
chmod 777 /sys/block/sdd/queue/iosched/group_idle
echo 1 > /sys/block/sdd/queue/iosched/group_idle
chmod 644 /sys/block/sdd/queue/iosched/group_idle
chmod 777 /sys/block/sdd/queue/iosched/low_latency
echo 1 > /sys/block/sdd/queue/iosched/low_latency
chmod 644 /sys/block/sdd/queue/iosched/low_latency
# Tune CFQ sched - sde (device)
chmod 777 /sys/block/sde/queue/iosched/back_seek_max
echo 16 > /sys/block/sde/queue/iosched/back_seek_max
chmod 644 /sys/block/sde/queue/iosched/back_seek_max
chmod 777 /sys/block/sde/queue/iosched/slice_idle
echo 0 > /sys/block/sde/queue/iosched/slice_idle
chmod 644 /sys/block/sde/queue/iosched/slice_idle
chmod 777 /sys/block/sde/queue/iosched/quantum
echo 32 > /sys/block/sde/queue/iosched/quantum
chmod 644 /sys/block/sde/queue/iosched/quantum
chmod 777 /sys/block/sde/queue/iosched/group_idle
echo 1 > /sys/block/sde/queue/iosched/group_idle
chmod 644 /sys/block/sde/queue/iosched/group_idle
chmod 777 /sys/block/sde/queue/iosched/low_latency
echo 1 > /sys/block/sde/queue/iosched/low_latency
chmod 644 /sys/block/sde/queue/iosched/low_latency
# Tune CFQ sched - sdf (device)
chmod 777 /sys/block/sdf/queue/iosched/back_seek_max
echo 16 > /sys/block/sdf/queue/iosched/back_seek_max
chmod 644 /sys/block/sdf/queue/iosched/back_seek_max
chmod 777 /sys/block/sdf/queue/iosched/slice_idle
echo 0 > /sys/block/sdf/queue/iosched/slice_idle
chmod 644 /sys/block/sdf/queue/iosched/slice_idle
chmod 777 /sys/block/sdf/queue/iosched/quantum
echo 32 > /sys/block/sdf/queue/iosched/quantum
chmod 644 /sys/block/sdf/queue/iosched/quantum
chmod 777 /sys/block/sdf/queue/iosched/group_idle
echo 1 > /sys/block/sdf/queue/iosched/group_idle
chmod 644 /sys/block/sdf/queue/iosched/group_idle
chmod 777 /sys/block/sdf/queue/iosched/low_latency
echo 1 > /sys/block/sdf/queue/iosched/low_latency
chmod 644 /sys/block/sdf/queue/iosched/low_latency

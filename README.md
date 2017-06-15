## Android Runtime Optimization

Android Lollipop includes a new virtual machine called ART (Android Runtime.) ART uses AOT (ahead-of-time) compilation into native code, which performs better than JIT (just-in-time) compilation into bytecode. You can configure ART to perform this optimization in different ways.
Android Lollipop includes the dex2oat tool for optimizing applications on deployment.

### Compiler Filters

In L, dex2oat takes a variety of --compiler-filter options to control how it compiles. Passing in a compiler filter flag for a particular app specifies how it’s pre-optimized. Here’s a description of each available option:

 * **_everything_** - compiles almost everything, excluding class initializers and some rare methods that are too large to be represented by the compiler’s internal representation.
 * **_speed_** - compiles most methods and maximizes runtime performance, which is the default option.
 * **_balanced_** - attempts to get the best performance return on compilation investment.
 * **_space_** - compiles a limited number of methods, prioritizing storage space.
 * **_interpret-only_** - skips all compilation and relies on the interpreter to run code.
 * **_verify-none_** - special option that skips verification and compilation, should be used only for trusted system code.

### Preference

#### Magisk

You can change the default compiler-filter with the one you prefer (or want to experiment with).
Just go to [Terminal Emulator](https://play.google.com/store/apps/details?id=jackpal.androidterm) and then type:

	art_magisk
![art_magisk](http://i.imgur.com/1HmveXF.png)

And then it'll present you with a menu that is pretty simple and easy to work with.
![art_magisk menu](http://i.imgur.com/OCME41l.png)

#### Non-Magisk

You can change the default compiler-filter with the one you prefer (or want to experiment with).
Just go to [Terminal Emulator](https://play.google.com/store/apps/details?id=jackpal.androidterm) and then type:

	setfilter [--compiler-filter] [file]
![setfilter]()

If you haven't entered your filter, it'll present you on how to use it.
![setfilter help]()

### UNIFIED Installer

With unified installer, the zip now installs whether you use Magisk, SuperSU or, if no other stuff is detected, Init.d.
It installs in this order according to detection:

` > Magisk > Systemless SuperSU > System SuperSU > Init.d`


### Changelog
#### v1.4.1
* setfilter needs root access!
* art_magisk needs root access!
* Dynamic version comment for Non-Magisk!
#### v1.4
* Code Optimization
* Another attempt for Samsung
* Added `setfilter` pseudo-binary for Non-Magisk
* Minor debloat
#### v1.3
* Workaround installation modified and fixed bugs
* Samsung + Xposed Warning in Installer
* Uninstaller Fixed
* Nexus 6P/other devices on 7.1+ issues fixed (removed pm.dexopt.bg-dexopt)
* Samsung + Xposed possible fix (needs testing)
* dalvik.vm.dex2oat-filter as the "Reference" property
#### v1.2.5
* Moved workaround installtion to config.sh, making it easier for me
* dalvik.vm.dex2oat-filter will also change when selection a filter, again
#### v1.2
* Revert dalvik.vm.dex2oat-filter to speed
* Removed dalvik-cache wiping during installation
* Removed dalvik.vm.boot-dex2oat-threads
* Tweaked Installation messages
* Tweaked davik-cache wiping in art_magisk
* Fixed "unknown operand" error in art_magisk
#### v1.1
* Logging Improved
* Saved compiler filter now survives updates on both Magisk and Non-Magisk (unless something prevents it to)
* Moved dalvik.vm.dex2oat-thread_count back to system.prop
* Add dalvik.vm.dex2oat-threads
* Add dalvik.vm.boot-dex2oat-threads
#### v1
* Unified Installer
* dalvik.vm.dex2oat-thread_count is now only applied Android 6+
`previous change logs deleted`


[More info about this topic here](https://source.android.com/devices/tech/dalvik/configure)

[See XDA Thread](https://forum.xda-developers.com/apps/magisk/module-android-runtime-optimization-t3596559)

[Non-Magisk (deprecated use UNIFIED instead)](https://www.androidfilehost.com/?w=files&flid=178198)

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

You can change the default compiler filter with the one you prefer (or want to experiment with).
Just go to [Terminal Emulator](https://play.google.com/store/apps/details?id=jackpal.androidterm) and then type:

	art_magisk
![art_magisk](http://i.imgur.com/1HmveXF.png)

And then it'll present you with a menu that is pretty simple and easy to work with.
![art_magisk menu](http://i.imgur.com/OCME41l.png)


### Changelog
#### v0.1 
* Initial Release
#### v0.2 
* post-fs-data.sh and service.sh is additionally used on setting properties
#### v0.3 
* post-fs-data.sh and service.sh now reads from system.prop
#### v0.3.1 
* fixed typo in post-fs-data.sh and service.sh
#### v0.4 
* Now has a UI in Terminal Emulator (how to use is in the OP)
* Default compiler filter is speed
* Automatically wipes dalvik-cache after flashing
#### v0.5 
* Added more properties
* Does not overwrite saved filter every update
* Removed post-fs-data.sh and service.sh
#### v0.6 
* Fixed bootloop issues
#### v0.7
* Added pm.dexopt.bg-dexopt for 7.1+
* Added dalvik.vm.dex2oat-swap for 7.1+ (enabled for low mem devices, disabled if not)


[More info about this topic here](https://source.android.com/devices/tech/dalvik/configure)

[See XDA Thread](https://forum.xda-developers.com/apps/magisk/module-android-runtime-optimization-t3596559)

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

This module, by default, uses **WITH_ART_SMALL_MODE** by default. You can go to this module's **system.prop** and change the value of `dalvik.vm.dex2oat-filter` to any of the given compiler filters above.

[More info about this topic here](https://source.android.com/devices/tech/dalvik/configure)

[See XDA Thread](https://forum.xda-developers.com/apps/magisk/module-android-runtime-optimization-t3596559)

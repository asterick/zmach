ZMach
=====

Z-Machine (V3) interpreter for the 0x10^c DCPU-16

My current goal is to make a 100% Version 3 compliant interpreter 
that is prebuilt to execute from memory.  Once there is a disk
drive standard, it will be very likely that I will support loading
and saving from disk, as well as loading alternate stories rather
than doing a static compile.

Due to the self destructive nature of z-machine stories, resetting, loading
and saving cannot be supported until disks are supported.

Current implemented features
----------------------------
* Optimized byte index-addressing
* Advanced multi-window display with support for scrolling, scroll lock and word wrap
* Configurable color output
* ZSCII output
* Preliminary z-machine runtime

Current task list
-----------------
* Interpreter core
    * Current instruction coverage: 34 of 69 implemented
    * Input tokenizer missing

Things to be added in the future
--------------------------------
* Loading and Saving to disk (stories, saves)
* Additional non keyboard and screen streams (1+)
* Sound support


ZMach
=====

Z-Machine (V3) interpreter for the 0x10^c DCPU-16

My current goal is to make a 100% Version 3 compliant interpreter 
that is prebuilt to execute from memory.  Once there is a disk
drive standard, it will be very likely that I will support loading
and saving from disk, as well as loading alternate stories rather
than doing a static compile.

Current implemented features
----------------------------
* Optimized byte index-addressing
* Advanced multi-window display with support for scrolling, scroll lock and word wrap
* Configurable color output
* ZSCII output

Current task list
-----------------
* Input tokenizer
* Interpreter core (started, incomplete)

Things to be added in the future
--------------------------------
* Loading and Saving to disk (stories, saves)
* Additional non keyboard and screen streams (1+)
* Sound support

# Using GTK4 from D (GDC) with importC

This is an example of using GTK4 in D without GtkD (D-language bindings), but directly via the GTK4 C-API. 

It uses GDC (D with GCC backend) and the integrated C compiler (importC).
GDC does not (yet) invoke the C preprocessor, so this has to be done explicitly in the makefile (creating `gtk4_import.i` from `gtk4_import.c`).

Very few GTK macros have to be replaced with D templates. Mainly the ones to connect to signals. But this is pretty straight forward. They are defined in `gtk4.d`.

The remaining annoyance is the extreme amount of explicit casting that is needed. 
That makes me appreciate GtkD language bindings which encapsulate GObjects inside of D classes and hide the casts.
But in principle it is very possible to use GTK4 directly with GDC.

The file `gdc_importc.h` is needed by importC. In dmd or ldc this was included, bin in gdc it was somehow missing, so I made a local copy.



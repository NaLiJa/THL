PASJPEG - August 23th, 1996
===========================


JPEG (pronounced "jay-peg") is a standardized familly of algorithms for
compression of still, continous tone images. JPEG is lossy, the output image
is not exactly identical to the input image. However, on typical photographic
images, very good compression levels can be obtained with no visible change,
and remarkably high compression levels are possible if you can tolerate a
low-quality image.

PASJPEG is a port of the Independent JPEG Group's (IJG) free, portable C
library for JPEG compression and decompression to Turbo Pascal 7.0 (TP) for
DOS. The code could easily be ported to other Pascal environments, since many
compilers try to be compatible to TP.

This work is based on rev. 6a of the IJG C source, that implements JPEG
baseline, extended-sequential, and progressive compression processes.
The IJG documentation (system architecture, using the IJG JPEG library,
usage and file list) is a must read. You may want to create online help from
the TP sources using the SCANHELP utility by Duncan J. Murdoch at SimTel and
garbo.

The files DEMO.PAS, TEST.PAS and EXAMPLE.PAS demonstrate the usage of the
JPEG decompression and compression library to dump JFIF files and to
create a JFIF file. The DJPEG application converts a JFIF file to a BMP or
TGA file. The RDJPGCOM application shows how to parse a JFIF file.

Notes:
======

* TO DO: Port the sample applications CJPEG, JPEGTRANS, WRJPGCOM.

* Verification:
  Please send in any errors you may discover in the code and in this
  README.TXT file.

* Environment variable JPEGMEM syntax changed;

* JMEMWIN renamed to JMEMNOBS

Translation
===========

TP is unit-centric, macros are not supported, everything was translated to
units, global conditional defines should go to an include file (not created
yet). Exported routines and types are declared are in the "interface" part
of the unit. TP doesn't need a make file.

The base type definitions are in the JMORECFG.PAS unit. The error codes are
in JDEFERR.PAS, the error handling macros have been converted to procedures
in JERROR.PAS. jpegint.h and jpeglib.h were merged into one large JPEGLIB.PAS
unit with all global type definition.

Once the header file are done, the translation turns into a lot of editing
work. Each C source file was converted to a unit by copying the "GLOBAL"
routines to the interface, editing the syntax (separate variable definition
and usage, define labels, group variable definitions, expanding macros, etc).

Some C  ->  Pascal  examples.

* "{"  -> "begin"    "->"  ->  "^."        " = "  -> " := "  "<<"  -> " shl "
  "}"  -> "end;"     "!="  ->  "<>"        " == " -> " = "   ">>"  -> " shr "
  "/*" -> "{"      routine ->  function    "0x"   -> "$"
  "*/" -> "}"      (void)      procedure   "NULL" -> "NIL"

* structs are records, Unions are variable records, pointers are always far(?),
  the operators && and || (and/or) have not the same priority in both
  languages, so parenthesis are important. The Pascal "case" doesn't have the
  falltrough option of the C "switch" statement, my work around is to split
  one "switch" statement into many case statements. The IJG source labels
  routines GLOBAL, METHODDEF and LOCAL. All globals routines are in the
  interface section of the units. The "far" directive is used for methods
  (METHODDEF).
* The pointer type in C is not readily interchangeable. It is used to address
  an array (Pascal pointer to an array) or in pointer arithmetic a pointer to
  a single element. I've used the Inc() statement with type casting to
  translate pointer arithmetic most of the time.

  C example:
    typedef JSAMPLE* JSAMPROW;  /* ptr to one image row of pixel samples. */

  Pascal
  type
    JSAMPLE_PTR = ^JSAMPLE;     { ptr to a single pixel sample. }
    jTSample = 0..(MaxInt div SIZEOF(JSAMPLE))-1;
    JSAMPLE_ARRAY = Array[jTSample] of JSAMPLE;  {far}
    JSAMPROW = ^JSAMPLE_ARRAY;  { ptr to one image row of pixel samples. }

  The following code

    JSAMPROW buffer0, buffer1;  /* ptr to a JSAMPLE buffer. */

    ...

    buffer1 = buffer0 + i;

  can be translated to

  var
    buffer0, buffer1 : JSAMPROW;

  ...

    buffer1 := buffer0;
    Inc(JSAMPLE_PTR(buffer1), i);

  or

    buffer1 := JSAMPROW(@ buffer0^[i]);

  Declaring the variables as JSAMPLE_PTR may reduce type casting in some
  places. I use help pointers to handle negative array offsets.

While translating the type of function parameter from C to Pascal, one can
often use "var", "const", or "array of" parameters instead of pointers.
While translating for(;;)-loops with more than one induction variable to
Pascal "for to/downto do"-loops, the extra induction variables be manually
updated at the end of the loop and before "continue"-statements.
statement.


Legal issues
============

Copyright (C) 1996 by Jacques Nomssi Nzali

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the author be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.


Archive Locations:
==================

The Independent JPEG Group C library for JPEG encoding and decoding, rev 6a.

  ftp://ftp.uu.net/graphics/jpeg/

  or SimTel in msdos/graphics/

Thomas G. Lane, JPEG FAQ

  in comp.graphics.misc and related newsgroups

Wallace, Gregory K.: The JPEG Still Picture Compression Standard

  ftp.uu.net, graphics/jpeg/wallace.ps.Z

JPEG implementation, written by the PVRG group at Stanford,
  ftp havefun.stanford.edu:/pub/jpeg/JPEGv1.2.tar.Z.

PASJPEG.ZIP at NView ftp site

  ftp://druckfix.physik.tu-chemnitz.de/pub/nv/

File list
=========

Here is my first try to provide a road map to the files in the PASJPEG
distribution (It may not be accurate yet).

readme.txt      Introduction, Documentation
example.pas	Sample code for calling JPEG library.
demo.pas        Demo program, uses example.pas
rdjpgcom.pas	Stand-alone rdjpgcom application.

Configuration/installation files

jconfig.inc	Configuration declarations.

jpeglib.pas	JPEG library's exported data and function declarations.
jmorecfg.pas	Additional configuration declarations; need not be changed
		for a standard installation.
jerror.pas	Declares JPEG library's error and trace message codes.
jinclude.pas

jdct.pas	Private declarations for forward & reverse DCT subsystems.

These files contain most of the functions intended to be called directly by
an application program:

jcapimin.pas	Application program interface: core routines for compression.
jcapistd.pas	Application program interface: standard compression.
jdapimin.pas	Application program interface: core routines for decompression.
jdapistd.pas	Application program interface: standard decompression.
jcomapi.pas	Application program interface routines common to compression
		and decompression.
jcparam.pas	Compression parameter setting helper routines.
jctrans.pas	API and library routines for transcoding compression.
jdtrans.pas	API and library routines for transcoding decompression.

Compression side of the library:

jcinit.pas	Initialization: determines which other modules to use.
jcmaster.pas	Master control: setup and inter-pass sequencing logic.
jcmainct.pas	Main buffer controller (preprocessor => JPEG compressor).
jcprepct.pas	Preprocessor buffer controller.
jccoefct.pas	Buffer controller for DCT coefficient buffer.
jccolor.pas	Color space conversion.
jcsample.pas	Downsampling.
jcdctmgr.pas	DCT manager (DCT implementation selection & control).
jfdctint.pas	Forward DCT using slow-but-accurate integer method.
jfdctfst.pas	Forward DCT using faster, less accurate integer method.
jfdctflt.pas	Forward DCT using floating-point arithmetic.
jchuff.pas	Huffman entropy coding for sequential JPEG.
jcphuff.pas	Huffman entropy coding for progressive JPEG.
jcmarker.pas	JPEG marker writing.
jdatadst.pas	Data destination manager for stdio output.

Decompression side of the library:

jdmaster.pas	Master control: determines which other modules to use.
jdinput.pas	Input controller: controls input processing modules.
jdmainct.pas	Main buffer controller (JPEG decompressor => postprocessor).
jdcoefct.pas	Buffer controller for DCT coefficient buffer.
jdpostct.pas	Postprocessor buffer controller.
jdmarker.pas	JPEG marker reading.
jdhuff.pas	Huffman entropy decoding for sequential JPEG.
jdphuff.pas	Huffman entropy decoding for progressive JPEG.
jddctmgr.pas	IDCT manager (IDCT implementation selection & control).
jidctint.pas	Inverse DCT using slow-but-accurate integer method.
jidctfst.pas	Inverse DCT using faster, less accurate integer method.
jidctflt.pas	Inverse DCT using floating-point arithmetic.
jidctred.pas	Inverse DCTs with reduced-size outputs.
jidct2d.pas	Direct 2D Inverse DCT - Do not compile
jdsample.pas	Upsampling.
jdcolor.pas	Color space conversion.
jdmerge.pas	Merged upsampling/color conversion (faster, lower quality).
jquant1.pas	One-pass color quantization using a fixed-spacing colormap.
jquant2.pas	Two-pass color quantization using a custom-generated colormap.
		Also handles one-pass quantization to an externally given map.
jdatasrc.pas	Data source manager for stdio input.

Support files for both compression and decompression:

jerror.pas	Standard error handling routines (application replaceable).
jmemmgr.pas	System-independent (more or less) memory management code.
jutils.pas	Miscellaneous utility routines.

jmemmgr.pas relies on a system-dependent memory management module.  The
PASJPEG distribution includes the following implementations of the system-
dependent module:

jmemnobs.pas	"No backing store": assumes adequate virtual memory exists.
jmemdos.pas	Custom implementation for MS-DOS: knows about extended and
		expanded memory as well as temporary files.

Exactly one of the system-dependent modules should be configured into an
installed JPEG library (see install.doc for hints about which one to use).
On unusual systems you may find it worthwhile to make a special
system-dependent memory manager.


jmemdosa.pas	80x86 assembly code support for jmemdos.pas; used only in
		MS-DOS-specific configurations of the JPEG library.

Additional Applications

cdjpeg.pas	Declarations shared by cjpeg/djpeg modules.
cderror.pas	Additional error and trace message codes for cjpeg/djpeg.
                Not used yet.

cjpeg.pas	Main program for cjpeg. - Do not compile
djpeg.pas	Main program for djpeg.
jpegtran.pas	Main program for jpegtran.- Do not compile
cdjpeg.pas	Utility routines used by all three programs.
rdcolmap.pas	Code to read a colormap file for djpeg's "-map" switch.
rdswitch.pas	Code to process some of cjpeg's more complex switches.
		Also used by jpegtran.

Image file writer modules for djpeg:

wrbmp.pas	BMP file output.
wrtarga.pas	Targa file output.


Jacques Nomssi Nzali
kn&n DES
nomssi@physik.tu-chemnitz.de
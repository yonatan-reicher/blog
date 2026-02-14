Compiling C/C++ code on Windows is such a mess. This page is just a summary of
things I read online when trying to understand the differences.

## WSL

WSL is just a Linux virtual machine. Your code will only run on Linux.

## MinGW

MinGW is the basics. You probably need this on your Windows machine, either
directly, or as part of one of the other toolchains below. MinGW is _the_ GCC
for windows. It's for building Windows applications. You can't call Linux things
from here.

## MinGW-W64

...

## Cygwin

Compiling on Windows, only for Linux. + letting you run a little bit of Linux.

## MSYS2

### MSYS

### UCRT MSYS

### CLANG MSYS

### MINGW MSYS

## W64DevKit



#!/bin/sh
set -x
dmd -debug -g -gf -gs -m64 generis.d
rm *.o

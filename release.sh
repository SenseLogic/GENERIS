#!/bin/sh
set -x
dmd -O -inline -m64 generis.d
rm *.o

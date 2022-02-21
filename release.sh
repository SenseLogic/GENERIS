#!/bin/sh
set -x
dmd -O -m64 generis.d
rm *.o

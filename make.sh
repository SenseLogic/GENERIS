#!/bin/sh
set -x
dmd -m64 generis.d
rm *.o

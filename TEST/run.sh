#!/bin/sh
set -x
../generis --process GS/ GO/ --trim --join
cd GO
go run test.go

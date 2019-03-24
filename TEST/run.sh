#!/bin/sh
set -x
../generis --process GS/ GO/ --trim --join --go
cd GO
go run test.go


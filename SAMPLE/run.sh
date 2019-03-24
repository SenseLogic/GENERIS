#!/bin/sh
set -x
../generis --process GS/ GO/ --trim --join --create --watch --go
cd GO
go run sample.go


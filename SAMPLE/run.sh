#!/bin/sh
set -x
../generis --process GS/ GO/ --join --go
cd GO
go run sample.go


#!/bin/sh
set -x
../generis --process GS/ GO/ --join
cd GO
go run test.go


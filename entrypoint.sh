#!/bin/sh

set -e

if [ "$DEBUG" = "1" ]; then
	make debug
else
	make
fi

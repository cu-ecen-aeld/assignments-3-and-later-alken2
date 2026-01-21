#!/bin/sh
# Writer script for writing text into a file
# Author: Kenneth Alcineus

if [ $# -lt 2 ]
then
    echo "Two arguments must be specified"
    exit 1
fi

writefile=$1
writestr=$2

if [ -d "$writefile" ]; then
    echo "The first argument must not be a directory"
    exit 1
fi

#1. ensure that the directory within the filepath already exists or is created if it doesn't
#2. ensure that the file could be written to

#the following solution is inspired by: https://linuxopsys.com/get-directory-path-in-bash
writedir=$(dirname "$writefile")

if ! mkdir -p "$writedir"; then
    echo "Could not create the required directory"
    exit 1
fi

if ! echo "$writestr" > "$writefile"; then
    echo "Could not write to file"
    exit 1
fi

echo "File written successfully"
#!/bin/sh
# Finder script for searching for text within files
# Author: Kenneth Alcineus

if [ $# -lt 2 ]
then
    echo "Two arguments must be specified"
    exit 1
fi

filesdir=$1
searchstr=$2

if [ ! -d "$filesdir" ]; then
    echo "The first argument specified is not a valid directory"
    exit 1
fi

#1. for each file in $filesdir
#   a. for every line in file
#       - increment searchcount if there is a string within the line that matches $searchstr
#   b. increment filecount
#2. print  "The number of files are filecount and the number of matching lines are searchcount"

filecount=0
searchcount=0

for file in ${filesdir}/*; do
    if [ -f "$file" ]; then 
        filecount=$((filecount + 1))
        # the following loop is based on the following source: https://phoenixnap.com/kb/bash-read-file-line-by-line
        while IFS= read -r line; do
            # the following conditional is based on the following source: https://stackoverflow.com/a/20460402
            case $line in
                *$searchstr* )
                    searchcount=$((searchcount + 1))
                    ;;
            esac 
        done <$file
    fi
done

echo "The number of files are ${filecount} and the number of matching lines are ${searchcount}"
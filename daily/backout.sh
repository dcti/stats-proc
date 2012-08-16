#!/bin/sh

if [ x$1 = x ]; then
    echo Must specify project ID!
    exit 1
fi

if [ x$2 = x ]; then
    echo Must specify last date to keep!
    exit 1
fi

psql -f backout.sql -v ProjectID=$1 -v "KeepDate='$2'" stats
psql -d stats -f clearday.sql -v ProjectID=$1

sudo diary "Stats rolled back for project $1 - last day kept $2"

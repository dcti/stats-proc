#!/bin/sh

if [ x$1 = x ]; then
    echo Must specify project ID!
    exit 1
fi

if [ x$2 = x ]; then
    echo Must specify last date to keep!
    exit 1
fi

psql -f audit.sql -v ProjectID=$1 -v "KeepDate='$2'" stats

#!/bin/sh

if [ x$1 = x ]; then
    echo Must specify project ID!
    exit 1
fi

pgsql -f audit.sql -v ProjectID=$1 stats

#!/bin/sh
#
# $Id: hourly.sh,v 1.3 2009/02/25 06:50:40 decibel Exp $

# We don't want to be trying to use some arbitrary auth info
unset SSH_AUTH_SOCK

cd ~/stats-proc/hourly && ./hourly.pl ~/workdir > ~/log/hourly.log  2> ~/log/hourly.err

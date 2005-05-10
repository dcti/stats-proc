#!/bin/sh
#
# $Id: hourly.sh,v 1.2 2005/05/10 23:12:56 decibel Exp $

cd ~/stats-proc/hourly && ./hourly.pl ~/workdir > ~/log/hourly.log  2> ~/log/hourly.err

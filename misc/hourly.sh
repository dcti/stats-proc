#!/bin/sh
#
# $Id: hourly.sh,v 1.1 2004/04/20 19:44:21 decibel Exp $

cd /home/statproc/stats-proc/hourly && ./hourly.pl /home/statproc/workdir > /home/statproc/log/hourly.log  2> /home/statproc/log/hourly.err

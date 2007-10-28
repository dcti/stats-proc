#!/bin/sh
# $Id: bcp.sh,v 1.5 2007/10/28 23:58:00 decibel Exp $
database=$1
filename=$2

psql -d $database -c "copy import FROM stdin WITH NULL AS ''  DELIMITER ','" < $filename

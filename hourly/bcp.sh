#!/bin/sh
# $Id: bcp.sh,v 1.1.2.1 2003/04/04 06:11:21 decibel Exp $
cat $2 | psql -d $1 -c "copy import_bcp FROM stdin DELIMITER ','"

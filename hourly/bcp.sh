#!/bin/sh
# $Id: bcp.sh,v 1.2 2003/09/11 01:41:02 decibel Exp $
cat $2 | psql -d $1 -c "copy import_bcp FROM stdin DELIMITER ','"

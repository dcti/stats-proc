#!/bin/sh
# $Id: bcp.sh,v 1.4 2007/10/28 21:28:59 nerf Exp $
database=$1
filename=$2
table=$3

psql -d $database -c "copy $table FROM stdin WITH NULL AS ''  DELIMITER ','" < $filename

#!/bin/sh
# $Id: initial.sh,v 1.6 2003/01/08 04:18:09 joel Exp $
#
psql -d ogrstats -f create_stubs.sql 

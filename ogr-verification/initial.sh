#!/bin/sh
# $Id: initial.sh,v 1.4 2003/01/01 17:01:05 joel Exp $
#
psql -d ogrstats -f create_stubs.sql -vprojnum=24
psql -d ogrstats -f create_stubs.sql -vprojnum=25

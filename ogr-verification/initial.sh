#!/bin/sh
# $Id: initial.sh,v 1.3 2002/12/21 21:13:22 joel Exp $
#
psql -d ogrstats -f create_stubs.sql

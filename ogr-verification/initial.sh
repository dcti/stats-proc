#!/bin/sh
# $Id: initial.sh,v 1.2 2002/12/20 23:55:45 nerf Exp $
#
psql -d ogrstats -f create_nodes.sql

#!/usr/bin/sqsh -i
#
# $Id: dy_importcount.sql,v 1.1 2003/09/11 02:05:45 decibel Exp $
#
# Returns the number of rows in the import table
#
# Arguments:
#       Project
#
# Returns:
#	Number of rows in table

select count(*) from ${1}_import
# Prevent output of the header or footer
go -f -h

#!/usr/bin/sqsh -i
#
# $Id: rowcount.sql,v 1.1 2003/09/11 02:05:45 decibel Exp $
#
# Returns how many rows are in a table
#
# Arguments:
#	Tablename and where clause
#
# Returns:
#	Rowcount

select count(*) from ${1}_master where date = '${2}'
# turn off header and rows affected output
go -f -h

#!/usr/bin/sqsh -i
#
# $Id: rowcount.sql,v 1.2 2000/04/14 21:32:55 bwilson Exp $
#
# Returns how many rows are in a table
#
# Arguments:
#	project_id and date
#
# Returns:
#	Rowcount

select count(*) from Email_Contrib where PROJECT_ID = ${1} and DATE = "${2}"
# turn off header and rows affected output
go -f -h

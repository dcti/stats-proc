#!/usr/bin/sqsh -i
#
# $Id: dy_checkday.sql,v 1.5 2000/04/14 21:32:55 bwilson Exp $
#
# Indicates if rows are in the master table for a given date
#
# Arguments:
#	Project
#	Date
#
# Returns:
#	zero/non-zero to indicate if data exists

if exists (select * from Email_Contrib where PROJECT_ID = ${1} and DATE = "${2}")
begin
	select 1
end
else
begin
	select 0
end

/* select count(*) from ${1}_master where date = "${2}" */
# turn off header and rows affected output
go -f -h

#!/usr/bin/sqsh -i
#
# $Id: dy_checkday.sql,v 1.4 2000/04/13 14:58:16 bwilson Exp $
#
# Indicates if rows are in the master table for a given date
#
# Arguments:
#	Project
#	Date
#
# Returns:
#	zero/non-zero to indicate if data exists

if exists (select * from ${1}_master where date = "${2}")
begin
	select 1
end
else
begin
	select 0
end

/* select count(*) from ${1}_master where date = '${2}' */
# turn off header and rows affected output
go -f -h

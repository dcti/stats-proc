#!/usr/bin/sqsh -i
#
# $Id: dy_checkday.sql,v 1.2 2000/02/21 03:47:06 bwilson Exp $
#
# Indicates if rows are in the master table for a given date
#
# Arguments:
#	Project
#	Date
#
# Returns:
#	zero/non-zero to indicate if data exists

if exists (select * from ${1}_master where date = \\'${2}\\')
begin
	select 1
end
else
begin
	select 0
end

/* select count(*) from ${1}_master where date = \\'${2}\\' */
# turn off header and rows affected output
go -f -h

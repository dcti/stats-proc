#!/usr/bin/sqsh -i
#
# $Id: cleardaytable.sql,v 1.5 2000/03/29 18:22:10 bwilson Exp $
#
# Recreates the daytables
#
# Arguments:
#       Project

if object_id('statproc_daytable') is not NULL
begin
	drop procedure statproc_${1}_ClearDay
end
go
create procedure statproc_${1}_ClearDay
as
begin
/* TODO: Decide which indexes to drop */
	drop index ${1}_Day_Master.
end
go
print 'Finished.'
go

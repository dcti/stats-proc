#!/usr/bin/sqsh -i
#
# $Id: cleardaytable.sql,v 1.4 2000/02/29 16:22:27 bwilson Exp $
#
# Recreates the daytables
#
# Arguments:
#       Project

if object_id('statproc_daytable') is not NULL
begin
	drop procedure statproc_cleardaytable
end
go
create procedure statproc_cleardaytable
as
begin
	drop index

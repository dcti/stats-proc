#!/usr/bin/sqsh -i
#
# $Id: clearimport.sql,v 1.5 2000/04/14 21:32:55 bwilson Exp $
#
# Recreates the import table
#
# Arguments:
#	Project

drop table ${1}_import
go

create table ${1}_import (
	TIME_STAMP	datetime,
	IP		varchar(15)	NULL,
	EMAIL		varchar(64)	NULL,
	PROJECT_ID	varchar(24)	NOT NULL,
	WORK_UNITS	numeric(20, 0)	NULL,
	OS		int NULL,
	CPU		int NULL,
	VER		int NULL
)
go


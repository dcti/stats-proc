#!/usr/bin/sqsh -i
#
# $Id: cleardaytable.sql,v 1.1 2000/02/09 16:13:57 nugget Exp $
#
# Recreates the daytables
#
# Arguments:
#       Project

drop table ${1}_daytable_master
go

create table ${1}_daytable_master (
	timestamp datetime,
	email char (64) NULL ,
	size int NULL ,
)
go

drop table ${1}_daytable_platform
go

create table ${1}_daytable_platform (
	timestamp datetime,
	cpu smallint NULL,
	os smallint NULL,
	ver smallint NULL,
	size int NULL
)
go


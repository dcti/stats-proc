#!/usr/bin/sqsh -i
#
# $Id: cleardaytable.sql,v 1.2 2000/02/10 15:13:54 bwilson Exp $
#
# Recreates the daytables
#
# Arguments:
#       Project

drop table ${1}_daytable_master
go

create table ${1}_daytable_master (
	timestamp datetime,
	email varchar (64) NULL ,
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


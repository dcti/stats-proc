#!/usr/bin/sqsh -i
#
# $Id: cleardaytable.sql,v 1.3 2000/02/21 03:47:06 bwilson Exp $
#
# Recreates the daytables
#
# Arguments:
#       Project

drop table ${1}_daytable_master
go

create table ${1}_daytable_master (
	timestamp datetime,
	project_id tinyint,
	email varchar (64) NULL ,
	size numeric(20, 0) NULL
)
go

drop table ${1}_daytable_platform
go

create table ${1}_daytable_platform (
	timestamp datetime,
	project_id tinyint,
	cpu smallint NULL,
	os smallint NULL,
	ver smallint NULL,
	size numeric(20, 0) NULL
)
go


#!/usr/bin/sqsh -i
#
# $Id: clearimport.sql,v 1.3 2000/02/21 03:47:06 bwilson Exp $
#
# Recreates the import table
#
# Arguments:
#	Project

drop table ${1}_import
go

create table ${1}_import (
	timestamp datetime,
	ip varchar (15) NULL ,
	email varchar (64) NULL ,
	blockid varchar (24) NOT NULL ,
	size numeric(20, 0) NULL ,
	os int NULL ,
	cpu int NULL ,
	ver int NULL
)
go


#!/usr/bin/sqsh -i
#
# $Id: clearimport.sql,v 1.2 2000/02/10 15:13:54 bwilson Exp $
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
	size int NULL ,
	os int NULL ,
	cpu int NULL ,
	ver int NULL
)
go


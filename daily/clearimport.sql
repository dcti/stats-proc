#!/usr/bin/sqsh -i
#
# $Id: clearimport.sql,v 1.4 2000/04/13 14:58:16 bwilson Exp $
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
	EMAIL varchar (64) NULL ,
	blockid varchar (24) NOT NULL ,
	size numeric(20, 0) NULL ,
	os int NULL ,
	CPU int NULL ,
	ver int NULL
)
go


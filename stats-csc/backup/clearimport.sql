#!/usr/bin/sqsh -i
#
# $Id: clearimport.sql,v 1.1 2003/09/11 02:05:45 decibel Exp $
#
# Recreates the import table
#
# Arguments:
#	Project

drop table ${1}_import
go

create table ${1}_import (
	timestamp datetime,
	ip char (15) NULL ,
	email char (64) NULL ,
	blockid char (24) NOT NULL ,
	size int NULL ,
	os int NULL ,
	cpu int NULL ,
	ver int NULL 
)
go


# $Id: clearimport.sql,v 1.1 1999/07/27 20:49:03 nugget Exp $

if exists (select * from sysobjects where id = object_id('import') and sysstat & 0xf = 3)
	drop table import
go

create table import (
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


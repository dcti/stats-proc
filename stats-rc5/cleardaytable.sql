# $Id: cleardaytable.sql,v 1.1 1999/07/27 20:49:02 nugget Exp $

drop table RC5_64_daytable_master
go

create table RC5_64_daytable_master (
	timestamp datetime,
	email char (64) NULL ,
	size int NULL ,
)
go

drop table RC5_64_daytable_platform
go

create table RC5_64_daytable_platform (
	timestamp datetime,
	cpu smallint NULL,
	os smallint NULL,
	ver smallint NULL,
	size int NULL
)
go


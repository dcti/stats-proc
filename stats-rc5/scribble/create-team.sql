use stats
go

CREATE TABLE stats.dbo.STATS_team (
	team numeric (10,0) IDENTITY NOT NULL,
	listmode smallint NULL,
	password char (8) NULL,
	name char (64) NULL ,
	url char (64) NULL ,
	contactname char (64) NULL,
	contactemail char (64) NULL,
	logo char (64) NULL,
	showmembers char (3) NULL,
	showpassword char (16) NULL,
	description text NULL
)
go

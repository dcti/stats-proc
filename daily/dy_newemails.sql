#!/usr/bin/sqsh -i
#
# $Id: dy_newemails.sql,v 1.5 2000/04/13 14:58:16 bwilson Exp $
#
# Adds new participants to stats_participant
#
# Arguments:
#       Project

print "!! Adding new EMAILs to stats_participant"
go
create table #dayemails
(
	ID		numeric(10, 0)	identity,
	EMAIL		varchar(64)	not NULL
)
go

print "::  Assigning ID and TEAM in Email_Contrib_Day"
go
/*
** When team-joins are handled as requests instead of live updates,
** the TEAM update will be handled from the requests table instead.
*/

update Email_Contrib_Day
	set ID = sp.ID,
		TEAM = sp.TEAM
	from STATS_Participant sp
	where sp.EMAIL = Email_Contrib_Day.EMAIL

create unique clustered index iID on Email_Contrib_Day(ID)
create index iTEAM on Email_Contrib_Day(TEAM)
go

print "::  Inserting all new EMAILs from daytable"
go

/*
** TODO: This might be faster without the Project information,
** but could induce blocking.  Need to test to be sure.
*/

declare @proj_id tinyint
select @proj_id = PROJECT_ID
	from Projects
	where NAME = "${1}"

insert #dayemails (EMAIL)
	select distinct EMAIL
	from Email_Contrib_Day
	where PROJECT_ID = @proj_id
		and ID = 0
	order by EMAIL
go

print "::  Adding new participants to stats_participant"
go
declare @idoffset int

select @idoffset = max(id)
	from STATS_Participant
	where id < 5000000

-- [BW] If we switch to retire_to = id as the normal condition,
--	this insert should insert (id, EMAIL, retire_to)
--	from id + @idoffset, EMAIL, id + @idoffset
insert into STATS_participant (ID, EMAIL)
	select ID + @idoffset, EMAIL
	from #dayemails
go
drop table #dayemails
drop table #allemails
go

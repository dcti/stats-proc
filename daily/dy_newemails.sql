#!/usr/bin/sqsh -i
#
# $Id: dy_newemails.sql,v 1.6 2000/04/14 21:32:55 bwilson Exp $
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

print "::  Assigning ID and TEAM in Email_Contrib_Today"
go
/*
** When team-joins are handled as requests instead of live updates,
** the TEAM update will be handled from the requests table instead.
**
** CREDIT_ID holds RETIRE_TO or ID.  Not unique, but guaranteed to
** be the ID that should get credit for this work.
*/

update Email_Contrib_Today
	set ID = sp.ID,
		TEAM_ID = sp.TEAM,
		CREDIT_ID = (abs(sign(sp.RETIRE_TO)) * sp.RETIRE_TO) + ((1 - abs(sign(sp.RETIRE_TO))) * sp.ID)
	from STATS_Participant sp
	where sp.EMAIL = Email_Contrib_Today.EMAIL
		and PROJECT_ID = ${1}

create unique clustered index iID on Email_Contrib_Today(ID)
create index iTEAM_ID on Email_Contrib_Today(TEAM_ID)
go

print "::  Inserting all new EMAILs from daytable"
go

/*
** TODO: This might be faster without the Project information,
** but could induce blocking.  Need to test to be sure.
*/

insert #dayemails (EMAIL)
	select distinct EMAIL
	from Email_Contrib_Today
	where PROJECT_ID = ${1}
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
--	from ID + @idoffset, EMAIL, ID + @idoffset
insert into STATS_participant (ID, EMAIL)
	select ID + @idoffset, EMAIL
	from #dayemails
go
drop table #dayemails
drop table #allemails
go

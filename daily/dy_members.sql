#!/usr/bin/sqsh -i
#
# $Id: dy_members.sql,v 1.5 2000/04/13 14:58:16 bwilson Exp $
#
# Create the team membership tables
#
# Arguments:
#       Project

print "!! Begin Team_Members Build"
go

use stats
set rowcount 0
go

print "::  Removing members who have been retired or hidden"
go
delete Team_Members
	from STATS_Participant sp
	where sp.ID = Team_Members.ID
		and (sp.RETIRE_TO >= 1 or sp.listmode >= 10)
go
create table #team_member_work1
(
	SEQN		numeric(10, 0) identity,
	ID		int,
	TEAM_ID		int,
	WORK_UNITS	numeric(20, 0)
)
go

create table #team_member_work2
(
	ID		int,
	TEAM_ID		int,
	WORK_UNITS	numeric(20, 0)
)
go

print "::  Inserting new members, and adding work for existing members"
go
insert #team_member_work1 (ID, TEAM_ID, WORK_UNITS)
	select odm.ID, odm.TEAM_ID, sum(odm.WORK_UNITS)
	from OGR_Email_Contrib_Day odm, STATS_Participant sp
	where odm.ID = sp.ID
		and odm.TEAM_ID > 0
		and odm.RETIRE_TO = 0
		and sp.LISTMODE <= 9
	group by odm.ID, odm.TEAM_ID
insert #team_member_work1 (ID, TEAM_ID, WORK_UNITS)
	select odm.RETIRE_TO, odm.TEAM_ID, sum(odm.WORK_UNITS)
	from OGR_Email_Contrib_Day odm, STATS_Participant sp
	where odm.ID = sp.ID
		and odm.TEAM_ID >= 1
		and odm.RETIRE_TO >= 1
		and sp.LISTMODE <= 9
	group by odm.RETIRE_TO, odm.TEAM_ID
go
insert #team_member_work2 (ID, TEAM_ID, WORK_UNITS)
	select ID, TEAM_ID, sum(WORK_UNITS)
	from #team_member_work1
	group by ID, TEAM_ID

drop table #team_member_work1
go
update Team_Members
	set LAST_DATE = getdate(),
		WORK_UNITS = Team_Members.WORK_UNITS + tmw.WORK_UNITS
	from #team_member_work2 tmw
	where tmw.ID = Team_Members.ID
		and tmw.TEAM_ID = Team_Members.TEAM_ID

delete #team_member_work2
	from Team_Members otm
	where otm.ID = #team_member_work2.ID
		and otm.TEAM_ID = #team_member_work2.TEAM_ID

insert Team_Members (ID, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_UNITS)
	select ID, TEAM_ID, getdate(), getdate(), WORK_UNITS
	from #team_member_work2

drop table #team_member_work2
go

#!/usr/bin/sqsh -i
#
# $Id: dy_members.sql,v 1.6 2000/04/14 21:32:55 bwilson Exp $
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
		and Team_Members.PROJECT_ID = ${1}
go
create table #team_member_work
(
	ID		int,
	TEAM_ID		int,
	WORK_UNITS	numeric(20, 0)
)
go

print "::  Inserting new members, and adding work for existing members"
go
declare @stats_date smalldatetime
select @stats_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

insert #team_member_work (ID, TEAM_ID, WORK_UNITS)
	select ect.CREDIT_ID, odm.TEAM_ID, sum(ect.WORK_UNITS)
	from Email_Contrib_Today ect, STATS_Participant sp
	where ect.ID = sp.ID
		and ect.TEAM_ID > 0
		and sp.LISTMODE <= 9
		and ect.PROJECT_ID = ${1}
	group by ect.CREDIT_ID, ect.TEAM_ID

update Team_Members
	set LAST_DATE = @stats_date,
		WORK_UNITS = Team_Members.WORK_UNITS + tmw.WORK_UNITS
	from #team_member_work tmw
	where tmw.ID = Team_Members.ID
		and tmw.TEAM_ID = Team_Members.TEAM_ID
		and Team_Members.PROJECT_ID = ${1}

delete #team_member_work
	from Team_Members otm
	where otm.ID = #team_member_work.ID
		and otm.TEAM_ID = #team_member_work.TEAM_ID
		and otm.PROJECT_ID = ${1}

insert Team_Members (PROJECT_ID, ID, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_UNITS)
	select ${1}, ID, TEAM_ID, getdate(), getdate(), WORK_UNITS
	from #team_member_work

drop table #team_member_work
go

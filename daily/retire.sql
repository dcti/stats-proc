#!/usr/bin/sqsh -i
#
# $Id: retire.sql,v 1.1 2000/07/17 11:37:30 decibel Exp $
#
# Handles all pending retire_to's and black-balls
#
# Arguments:
#       Project_id

use stats
set rowcount 0
go

print 'Remove retired or hidden participants from Email_Rank'
go
begin transaction
select RETIRE_TO, WORK_TOTAL
	into #NewRetiresER
	from Email_Rank er, STATS_Participant sp
	where sp.ID = er.ID
		and sp.RETIRE_TO >= 1

update Email_Rank
	set Email_Rank.WORK_TOTAL = Email_Rank.WORK_TOTAL + nr.WORK_TOTAL
	from #NewRetiresER nr
	where Email_Rank.ID = nr.RETIRE_TO

delete Email_Rank
	from STATS_Participant
	where STATS_Participant.ID = Email_Rank.ID
		and (STATS_Participant.RETIRE_TO >= 1
			or STATS_Participant.listmode >= 10)
		and PROJECT_ID = ${1}
commit transaction
go

print 'Remove retired or hidden participants from Email_Rank'
go
begin transaction
select RETIRE_TO, TEAM_ID, WORK_TOTAL
	into #NewRetiresTM
	from Team_Members er, STATS_Participant sp
	where sp.ID = er.ID
		and sp.RETIRE_TO >= 1

update Team_Members
	set Team_Members.WORK_TOTAL = Team_Members.WORK_TOTAL + nr.WORK_TOTAL
	from #NewRetiresTM nr
	where Team_Members.ID = nr.RETIRE_TO
		and Team_Members.TEAM_ID = nr.TEAM_ID

delete Team_Members
	from STATS_Participant sp
	where sp.ID = Team_Members.ID
		and (sp.RETIRE_TO >= 1
			or sp.LISTMODE >= 10)
		and Team_Members.PROJECT_ID = ${1}
commit transaction
go

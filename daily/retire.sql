#!/usr/bin/sqsh -i
#
# $Id: retire.sql,v 1.6 2000/07/18 10:46:58 decibel Exp $
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
select RETIRE_TO, WORK_TOTAL, FIRST_DATE, LAST_DATE
	into #NewRetiresER
	from Email_Rank er, STATS_Participant sp
	where sp.ID = er.ID
		and sp.RETIRE_TO >= 1
		and sp.LISTMODE <= 9
		and er.PROJECT_ID = ${1}

begin transaction
update Email_Rank
	set Email_Rank.WORK_TOTAL = Email_Rank.WORK_TOTAL + nr.WORK_TOTAL
	from #NewRetiresER nr
	where Email_Rank.ID = nr.RETIRE_TO
		and Email_Rank.PROJECT_ID = ${1}
update Email_Rank
	set Email_Rank.FIRST_DATE = nr.FIRST_DATE
	from #NewRetiresER nr
	where Email_Rank.ID = nr.RETIRE_TO
		and Email_Rank.FIRST_DATE > nr.FIRST_DATE
		and Email_Rank.PROJECT_ID = ${1}
update Email_Rank
	set Email_Rank.LAST_DATE = nr.LAST_DATE
	from #NewRetiresER nr
	where Email_Rank.ID = nr.RETIRE_TO
		and Email_Rank.LAST_DATE < nr.LAST_DATE
		and Email_Rank.PROJECT_ID = ${1}

delete Email_Rank
	from STATS_Participant
	where STATS_Participant.ID = Email_Rank.ID
		and (STATS_Participant.RETIRE_TO >= 1
			or STATS_Participant.listmode >= 10)
		and Email_Rank.PROJECT_ID = ${1}

-- The following code should ensure that any "retire_to chains" eventually get eliminated
-- It is also needed in case someone retires to an address that hasnt done any work in
-- this contest.
delete #NewRetiresER
	from Email_Rank er
	where #NewRetiresER.RETIRE_TO = er.ID

insert into Email_Rank(PROJECT_ID, ID, FIRST_DATE, LAST_DATE, WORK_TOTAL)
	select ${1}, RETIRE_TO, FIRST_DATE, LAST_DATE, WORK_TOTAL
	from #NewRetiresER

commit transaction
go

print 'Remove retired or hidden participants from Team_Members'
go
select RETIRE_TO, TEAM_ID, WORK_TOTAL, FIRST_DATE, LAST_DATE
	into #NewRetiresTM
	from Team_Members tm, STATS_Participant sp
	where sp.ID = tm.ID
		and sp.RETIRE_TO >= 1
		and sp.LISTMODE <= 9
		and tm.PROJECT_ID = ${1}

begin transaction
update Team_Members
	set Team_Members.WORK_TOTAL = Team_Members.WORK_TOTAL + nr.WORK_TOTAL
	from #NewRetiresTM nr
	where Team_Members.ID = nr.RETIRE_TO
		and Team_Members.TEAM_ID = nr.TEAM_ID
		and Team_Members.PROJECT_ID = ${1}
update Team_Members
	set Team_Members.FIRST_DATE = nr.FIRST_DATE
	from #NewRetiresTM nr
	where Team_Members.ID = nr.RETIRE_TO
		and Team_Members.TEAM_ID = nr.TEAM_ID
		and Team_Members.PROJECT_ID = ${1}
		and Team_Members.FIRST_DATE > nr.FIRST_DATE
update Team_Members
	set Team_Members.LAST_DATE = nr.LAST_DATE
	from #NewRetiresTM nr
	where Team_Members.ID = nr.RETIRE_TO
		and Team_Members.TEAM_ID = nr.TEAM_ID
		and Team_Members.PROJECT_ID = ${1}
		and Team_Members.LAST_DATE < nr.LAST_DATE

delete Team_Members
	from STATS_Participant sp
	where sp.ID = Team_Members.ID
		and (sp.RETIRE_TO >= 1
			or sp.LISTMODE >= 10)
		and Team_Members.PROJECT_ID = ${1}

-- This code *must* stay in order to handle retiring participants old team affiliations
delete #NewRetiresTM
	from Team_Members tm
	where #NewRetiresTM.RETIRE_TO = tm.ID
		and #NewRetiresTM.TEAM_ID = tm.TEAM_ID

insert into Team_Members(PROJECT_ID, ID, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_TOTAL)
	select ${1}, RETIRE_TO, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_TOTAL
	from #NewRetiresTM

commit transaction
go

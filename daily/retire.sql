#!/usr/bin/sqsh -i
#
# $Id: retire.sql,v 1.18 2002/04/10 16:49:05 decibel Exp $
#
# Handles all pending retire_tos and black-balls
#
# Arguments:
#       Project_id

use stats
set rowcount 0
go

print 'Build a list of blocked participants'
go
select ID into #Blocked
	from STATS_Participant
	where LISTMODE >= 10
go
insert into #Blocked(ID)
	select ID
	from STATS_Participant sp, #Blocked b
	where sp.RETIRE_TO > 0
		and sp.RETIRE_TO = b.ID
go

print 'Update STATS_Participant_Blocked'
go
insert into STATS_Participant_Blocked(ID)
	select ID
	from #Blocked b
	where not exists (select *
				from STATS_Participant_Blocked spb
				where spd.ID = b.ID)
delete from STATS_Participant_Blocked spb
	where ID not in (select ID from #Blocked)
go

print 'Update STATS_Team_Blocked'
go
insert into STATS_Team_Blocked(TEAM_ID)
	select TEAM
	from STATS_Team st
	where st.LISTMODE >= 10
		and TEAM not in (select TEAM_ID
					from STATS_Team_Blocked stb
					where std.TEAM_ID = st.TEAM_ID
				)

delete from STATS_Team_Blocked
	where not exists (select *
				from STATS_Team
				where LISTMODE >= 10
			)
go

print 'Remove retired or hidden participants from Email_Rank'
go
declare @stats_date smalldatetime
select @stats_date = LAST_HOURLY_DATE
	from Project_statsrun
	where PROJECT_ID = ${1}

select RETIRE_TO, WORK_TOTAL, FIRST_DATE, LAST_DATE
	into #temp
	from Email_Rank er, STATS_Participant sp
	where sp.ID = er.ID
		and sp.RETIRE_TO >= 1
		and sp.RETIRE_DATE = @stats_date
		and not exists (select *
					from STATS_Participant_Blocked spb
					where spb.ID = sp.ID
						and spb.ID = er.ID
				)
		and er.PROJECT_ID = ${1}

select RETIRE_TO, sum(WORK_TOTAL) as WORK_TOTAL, min(FIRST_DATE) as FIRST_DATE, max(LAST_DATE) as LAST_DATE
	into #NewRetiresER
	from #temp
	group by RETIRE_TO
go
drop table #temp
--select * from #NewRetiresER
go

print "Begin update"
set flushmessage on
go
begin transaction
print "Update Email_Rank with new information"
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

print ""
print ""
print "Delete retires and blocked participants from Email_Rank"
declare @stats_date smalldatetime
select @stats_date = LAST_HOURLY_DATE
	from Project_statsrun
	where PROJECT_ID = ${1}

delete Email_Rank
	from STATS_Participant
	where STATS_Participant.ID = Email_Rank.ID
		and STATS_Participant.RETIRE_TO >= 1
		and STATS_Participant.RETIRE_DATE = @stats_date
		and Email_Rank.PROJECT_ID = ${1}

delete Email_Rank
	from STATS_Participant_Blocked spb
	where spb.ID = Email_Rank.ID

-- The following code should ensure that any "retire_to chains" eventually get eliminated
-- It is also needed in case someone retires to an address that hasnt done any work in
-- this contest.
print "Insert remaining retires"
delete #NewRetiresER
	from Email_Rank er
	where #NewRetiresER.RETIRE_TO = er.ID
		and er.PROJECT_ID = ${1}

insert into Email_Rank(PROJECT_ID, ID, FIRST_DATE, LAST_DATE, WORK_TOTAL)
	select ${1}, RETIRE_TO, FIRST_DATE, LAST_DATE, WORK_TOTAL
	from #NewRetiresER

--select * from #NewRetiresER

commit transaction
go

set flushmessage off
print 'Remove retired participants from Team_Members'
go
print 'Select new retires'
declare @stats_date smalldatetime
select @stats_date = LAST_HOURLY_DATE
	from Project_statsrun
	where PROJECT_ID = ${1}

select RETIRE_TO, TEAM_ID, WORK_TOTAL, FIRST_DATE, LAST_DATE
	into #temp
	from Team_Members tm, STATS_Participant sp
	where sp.ID = tm.ID
		and sp.RETIRE_TO >= 1
		and sp.RETIRE_DATE = @stats_date
		and not exists (select *
					from STATS_Participant_Blocked spb
					where spb.ID = sp.ID
						and spb.ID = tm.ID
				)
		and tm.PROJECT_ID = ${1}

select RETIRE_TO, TEAM_ID, sum(WORK_TOTAL) as WORK_TOTAL, min(FIRST_DATE) as FIRST_DATE, max(LAST_DATE) as LAST_DATE
	into #NewRetiresTM
	from #temp
	group by RETIRE_TO, TEAM_ID
go
drop table #temp
--select * from #NewRetiresTM
go

set flushmessage on
print "Begin update"
go
begin transaction
print "Update Team_Members with new information for retires"
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

print "Delete retires from Team_Members"
declare @stats_date smalldatetime
select @stats_date = LAST_HOURLY_DATE
	from Project_statsrun
	where PROJECT_ID = ${1}

delete Team_Members
	from STATS_Participant sp
	where sp.ID = Team_Members.ID
		and sp.RETIRE_TO >= 1
		and sp.RETIRE_DATE = @stats_date
		and Team_Members.PROJECT_ID = ${1}

-- This code *must* stay in order to handle retiring participants old team affiliations
print ""
print ""
print "Insert remaining retires"
delete #NewRetiresTM
	from Team_Members tm
	where #NewRetiresTM.RETIRE_TO = tm.ID
		and #NewRetiresTM.TEAM_ID = tm.TEAM_ID
		and tm.PROJECT_ID = ${1}

insert into Team_Members(PROJECT_ID, ID, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_TOTAL)
	select ${1}, RETIRE_TO, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_TOTAL
	from #NewRetiresTM

--select * from #NewRetiresTM

commit transaction
go

set flushmessage off
print "Remove hidden participants"
go
print "Select IDs to remove"
select distinct sp.ID
	into #BadIDs
	from Team_Members tm, STATS_Participant_Blocked spb
	where tm.ID = spb.ID
		and PROJECT_ID = ${1}
go

print "Summarize team work to be removed"
select TEAM_ID, sum(WORK_TOTAL) as BAD_WORK_TOTAL
	into #BadWork
	from Team_Members tm, #BadIDs b
	where tm.ID = b.ID
		and PROJECT_ID = ${1}
	group by TEAM_ID
go

set flushmessage on
go
begin transaction
print "Update Team_Rank to account for removed IDs"
update Team_Rank
	set WORK_TOTAL = WORK_TOTAL - BAD_WORK_TOTAL
	from #BadWork bw
	where Team_Rank.TEAM_ID = bw.TEAM_ID

print "Delete from Team_Members"
delete Team_Members
	from #BadIDs b
	where Team_Members.ID = b.ID
		and Team_Members.PROJECT_ID = ${1}
commit transaction
go

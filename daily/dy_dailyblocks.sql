#!/usr/bin/sqsh -i
#
# $Id: dy_dailyblocks.sql,v 1.11 2002/04/10 16:49:05 decibel Exp $
#
# Inserts the daily totals
#
# Arguments:
#       Project

declare @stats_date smalldatetime,
	@count int,
	@work numeric(20, 0)

select @stats_date = LAST_HOURLY_DATE
	from Project_statsrun
	where PROJECT_ID = ${1}

insert Daily_Summary (DATE, PROJECT_ID, WORK_UNITS,
		PARTICIPANTS, PARTICIPANTS_NEW, TOP_OPARTICIPANT, TOP_OPWORK, TOP_YPARTICIPANT, TOP_YPWORK,
		TEAMS, TEAMS_NEW, TOP_OTEAM, TOP_OTWORK, TOP_YTEAM, TOP_YTWORK)
	values (@stats_date, ${1}, 0,
		0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0)

--
-- Total Work Units
--
select @work = sum(WORK_UNITS)
	from Email_Contrib_Today
	where PROJECT_ID = ${1}
update Daily_Summary
	set WORK_UNITS = @work
	where Daily_Summary.date = @stats_date
		and Daily_Summary.PROJECT_ID = ${1}

--
-- Number of Participants
--
select @count = count(distinct ect.CREDIT_ID)
	from Email_Contrib_Today ect
	where ect.CREDIT_ID not in (select ID
					from STATS_Participant_Blocked
				)
		and ect.PROJECT_ID = ${1}
update Daily_Summary
	set PARTICIPANTS = @count
	where Daily_Summary.date = @stats_date
		and Daily_Summary.PROJECT_ID = ${1}

--
-- Number of New Participants
--
select @count = count(*)
	from Email_Rank
		where FIRST_DATE = @stats_date
			and PROJECT_ID = ${1}
update Daily_Summary
	set PARTICIPANTS_NEW = @count
	where Daily_Summary.date = @stats_date
		and Daily_Summary.PROJECT_ID = ${1}

--
-- Number of Teams
--
select @count = count(distinct TEAM_ID)
	from Email_Contrib_Today ect
	where ect.TEAM_ID >= 1
		and ect.TEAM_ID not in (select TEAM_ID
						from STATS_Team_Blocked
					)
		and ect.PROJECT_ID = ${1}
update Daily_Summary
	set teams = @count
	where Daily_Summary.date = @stats_date
		and Daily_Summary.PROJECT_ID = ${1}

--
-- Number of New Teams
--
select @count = count(*)
	from Team_Rank
		where FIRST_DATE = @stats_date
			and PROJECT_ID = ${1}
update Daily_Summary
	set TEAMS_NEW = @count
	where Daily_Summary.date = @stats_date
		and Daily_Summary.PROJECT_ID = ${1}

--
-- Top Participant Info, Overall
--
update Daily_Summary
	set TOP_OPARTICIPANT = r.ID,
		TOP_OPWORK = r.WORK_TOTAL
	from Email_Rank r
	where Daily_Summary.date = @stats_date
		and Daily_Summary.PROJECT_ID = ${1}
		and r.PROJECT_ID = ${1}
		and r.OVERALL_RANK = 1

--
-- Top Participant Info for Yesterday
--
update Daily_Summary
	set TOP_YPARTICIPANT = r.ID,
		TOP_YPWORK = r.WORK_TODAY
	from Email_Rank r
	where Daily_Summary.date = @stats_date
		and Daily_Summary.PROJECT_ID = ${1}
		and r.PROJECT_ID = ${1}
		and r.DAY_RANK = 1

--
-- Top Team Info, Overall
--
update Daily_Summary
	set TOP_OTEAM = r.TEAM_ID,
		TOP_OTWORK = r.WORK_TOTAL
	from Team_Rank r
	where Daily_Summary.date = @stats_date
		and Daily_Summary.PROJECT_ID = ${1}
		and r.PROJECT_ID = ${1}
		and r.OVERALL_RANK = 1

--
-- Top Team Info for Yesterday
--
update Daily_Summary
	set TOP_YTEAM = r.TEAM_ID,
		TOP_YTWORK = r.WORK_TODAY
	from Team_Rank r
	where Daily_Summary.date = @stats_date
		and Daily_Summary.PROJECT_ID = ${1}
		and r.PROJECT_ID = ${1}
		and r.DAY_RANK = 1
go

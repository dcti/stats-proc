#!/usr/bin/sqsh -i
#
# $Id: dy_dailyblocks.sql,v 1.8 2000/06/28 10:59:02 decibel Exp $
#
# Inserts the daily totals
#
# Arguments:
#       Project

declare @stats_date smalldatetime,
	@count int,
	@work numeric(20, 0)

select @stats_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

insert Daily_Summary (DATE, PROJECT_ID, WORK_UNITS,
		PARTICIPANTS, PARTICIPANTS_NEW, TOP_OPARTICIPANT, TOP_OPWORK, TOP_YPARTICIPANT, TOP_YPWORK,
		TEAMS, TEAMS_NEW, TOP_OTEAM, TOP_OTWORK, TOP_YTEAM, TOP_YTWORK)
	values (@stats_date, ${1}, 0,
		0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0)

select @work = sum(WORK_UNITS),
		@count = count(*)
	from Email_Contrib_Today
	where PROJECT_ID = ${1}
update Daily_Summary
	set WORK_UNITS = @work,
		PARTICIPANTS = @count
	where Daily_Summary.date = @stats_date
		and Daily_Summary.PROJECT_ID = ${1}

select @count = count(*)
	from Email_Rank
		where FIRST_DATE = @stats_date
			and PROJECT_ID = ${1}
update Daily_Summary
	set PARTICIPANTS_NEW = @count
	where Daily_Summary.date = @stats_date
		and Daily_Summary.PROJECT_ID = ${1}

select @count = count(distinct TEAM_ID)
	from Email_Contrib_Today
	where TEAM_ID >= 1
		and PROJECT_ID = ${1}
update Daily_Summary
	set teams = @count
	where Daily_Summary.date = @stats_date
		and Daily_Summary.PROJECT_ID = ${1}

select @count = count(*)
	from Team_Rank
		where FIRST_DATE = @stats_date
			and PROJECT_ID = ${1}
update Daily_Summary
	set TEAMS_NEW = @count
	where Daily_Summary.date = @stats_date
		and Daily_Summary.PROJECT_ID = ${1}

update Daily_Summary
	set TOP_OPARTICIPANT = r.ID,
		TOP_OPWORK = r.WORK_TOTAL
	from Email_Rank r
	where Daily_Summary.date = @stats_date
		and Daily_Summary.PROJECT_ID = ${1}
		and r.PROJECT_ID = ${1}
		and r.OVERALL_RANK = 1

update Daily_Summary
	set TOP_YPARTICIPANT = r.ID,
		TOP_YPWORK = r.WORK_TODAY
	from Email_Rank r
	where Daily_Summary.date = @stats_date
		and Daily_Summary.PROJECT_ID = ${1}
		and r.PROJECT_ID = ${1}
		and r.DAY_RANK = 1

update Daily_Summary
	set TOP_OTEAM = r.TEAM_ID,
		TOP_OTWORK = r.WORK_TOTAL
	from Team_Rank r
	where Daily_Summary.date = @stats_date
		and Daily_Summary.PROJECT_ID = ${1}
		and r.PROJECT_ID = ${1}
		and r.OVERALL_RANK = 1

update Daily_Summary
	set TOP_YTEAM = r.TEAM_ID,
		TOP_YTWORK = r.WORK_TODAY
	from Team_Rank r
	where Daily_Summary.date = @stats_date
		and Daily_Summary.PROJECT_ID = ${1}
		and r.PROJECT_ID = ${1}
		and r.DAY_RANK = 1
go

#!/usr/bin/sqsh -i
#
# $Id: dy_dailyblocks.sql,v 1.5 2000/04/13 14:58:16 bwilson Exp $
#
# Inserts the daily totals
#
# Arguments:
#       Project

declare @stats_date smalldatetime
declare @proj_id tinyint
declare @count int,
	@work numeric(20, 0)

select @stats_date = LAST_STATS_DATE,
		@proj_id = PROJECT_ID
	from Projects
	where NAME = "${1}"

insert Daily_Summary (date, PROJECT_ID, WORK_UNITS,
		participants, TOP_oparticipant, TOP_OPWORK, TOP_YPARTICIPANT, TOP_YPWORK,
		teams, TOP_OTEAM, TOP_OTWORK, TOP_yteam, TOP_YTWORK)
	values (@stats_date, @proj_id, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0)

select @work = sum(WORK_UNITS) 'WORK_UNITS',
		@count = count(*) 'PARTICIPANTS'
	from Email_Contrib_Day
	where PROJECT_ID = @proj_id

update Daily_Summary
	set WORK_UNITS = @work,
		PARTICIPANTS = @count
	where Daily_Summary.date = @stats_date
		and Daily_Summary.PROJECT_ID = @proj_id

select @count = count(distinct team)
	from Email_Contrib_Day
	where TEAM > 0

update Daily_Summary
	set teams = @count
	where Daily_Summary.date = @stats_date
		and Daily_Summary.PROJECT_ID = @proj_id

update Daily_Summary
	set TOP_OPARTICIPANT = r.ID,
		TOP_OPWORK = r.WORK_TOTAL
	from ${1}_Email_Rank r
	where Daily_Summary.date = @stats_date
		and Daily_Summary.PROJECT_ID = @proj_id
		and r.OVERALL_RANK = 1

update Daily_Summary
	set TOP_YPARTICIPANT = r.ID,
		TOP_YPWORK = r.WORK_TODAY
	from ${1}_Email_Rank r
	where Daily_Summary.date = @stats_date
		and Daily_Summary.PROJECT_ID = @proj_id
		and r.DAY_RANK = 1

update Daily_Summary
	set TOP_OTEAM = r.TEAM,
		TOP_OTEAMRANK = r.WORK_TOTAL
	from ${1}_Team_Rank r
	where Daily_Summary.date = @stats_date
		and Daily_Summary.PROJECT_ID = @proj_id
		and r.OVERALL_RANK = 1

update Daily_Summary
	set TOP_YTEAM = r.TEAM,
		TOP_YTEAMRANK = r.WORK_TODAY
	from ${1}_Team_Rank r
	where Daily_Summary.date = @stats_date
		and Daily_Summary.PROJECT_ID = @proj_id
		and r.DAY_RANK = 1
go
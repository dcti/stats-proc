#!/usr/bin/sqsh -i
#
# $Id: dy_dailyblocks.sql,v 1.3 2000/03/29 18:22:10 bwilson Exp $
#
# Inserts the daily totals
#
# Arguments:
#       Project

declare @stats_date smalldatetime
declare @proj_id tinyint

select @stats_date = LAST_STATS_DATE,
		@proj_id = PROJECT_ID
	from Projects
	where NAME = '${1}'

insert ${1}_dailies (date, WORK_UNITS,
		participants, TOP_oparticipant, TOP_OPWORK, TOP_YPARTICIPANT, TOP_YPWORK,
		teams, TOP_OTEAM, TOP_OTWORK, TOP_yteam, TOP_YTWORK)
	values (@stats_date, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0)

update ${1}_dailies
	set WORK_UNITS = sum(m.WORK_UNITS),
		PARTICIPANTS = count(*)
	from ${1}_master m
	where ${1}_dailies.date = @stats_date
		and m.date = @stats_date

update ${1}_dailies
	set TOP_OPARTICIPANT = r.ID,
		TOP_OPWORK = r.WORK_UNITS
	from ${1}_Rank r
	where ${1}_dailies.date = @stats_date
		and r.RANK = 1



insert into ${1}_dailies (date, blocks,
                           participants, TOP_oparticipant, TOP_OPWORK, TOP_YPARTICIPANT, TOP_YPWORK,
                           teams, TOP_OTEAM, TOP_OTWORK, TOP_yteam, TOP_YTWORK)
select
  (select max(date) from ${1}_master) as date,
  (select sum(blocks) from ${1}_master where date = (select max(date) from ${1}_master)) as blocks,
  (select count(*) from ${1}_master where date = (select max(date) from ${1}_master)) as participants,
  (select id from stats.statproc.${1}_CACHE_em_RANK where Rank = 1) as TOP_oparticpant,
  (select blocks from stats.statproc.${1}_CACHE_em_RANK where Rank = 1) as TOP_OPWORK,
  (select id from stats.statproc.${1}_CACHE_em_YRANK where Rank = 1) as TOP_yparticpant,
  (select blocks from stats.statproc.${1}_CACHE_em_YRANK where Rank = 1) as TOP_YPWORK,
  (select count(team) from stats.statproc.${1}_CACHE_tm_YRANK) as teams,
  (select team from stats.statproc.${1}_CACHE_tm_RANK where Rank = 1) as TOP_OTEAM,
  (select blocks from stats.statproc.${1}_CACHE_tm_RANK where Rank = 1) as TOP_OTWORK,
  (select team from stats.statproc.${1}_CACHE_tm_YRANK where Rank = 1) as TOP_yteam,
  (select blocks from stats.statproc.${1}_CACHE_tm_YRANK where Rank = 1) as TOP_YTWORK
go

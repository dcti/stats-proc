#!/usr/bin/sqsh -i
#
# $Id: dy_dailyblocks.sql,v 1.2 2000/02/29 16:22:27 bwilson Exp $
#
# Inserts the daily totals
#
# Arguments:
#       Project

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

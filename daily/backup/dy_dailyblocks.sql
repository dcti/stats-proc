#!/usr/bin/sqsh -i
#
# $Id: dy_dailyblocks.sql,v 1.1 2000/02/09 16:13:58 nugget Exp $
#
# Inserts the daily totals
#
# Arguments:
#       Project

insert into ${1}_dailies (date, blocks,
                           participants, top_oparticipant, top_opblocks, top_yparticipant, top_ypblocks,
                           teams, top_oteam, top_otblocks, top_yteam, top_ytblocks)
select 
  (select max(date) from ${1}_master) as date,
  (select sum(blocks) from ${1}_master where date = (select max(date) from ${1}_master)) as blocks,
  (select count(*) from ${1}_master where date = (select max(date) from ${1}_master)) as participants,
  (select id from stats.statproc.${1}_CACHE_em_RANK where Rank = 1) as top_oparticpant,
  (select blocks from stats.statproc.${1}_CACHE_em_RANK where Rank = 1) as top_opblocks,
  (select id from stats.statproc.${1}_CACHE_em_YRANK where Rank = 1) as top_yparticpant,
  (select blocks from stats.statproc.${1}_CACHE_em_YRANK where Rank = 1) as top_ypblocks,
  (select count(team) from stats.statproc.${1}_CACHE_tm_YRANK) as teams,
  (select team from stats.statproc.${1}_CACHE_tm_RANK where Rank = 1) as top_oteam,
  (select blocks from stats.statproc.${1}_CACHE_tm_RANK where Rank = 1) as top_otblocks,
  (select team from stats.statproc.${1}_CACHE_tm_YRANK where Rank = 1) as top_yteam,
  (select blocks from stats.statproc.${1}_CACHE_tm_YRANK where Rank = 1) as top_ytblocks
go

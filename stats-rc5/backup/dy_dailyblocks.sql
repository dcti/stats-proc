# $Id: dy_dailyblocks.sql,v 1.1 2003/09/11 02:04:01 decibel Exp $

insert into STATS_dailies (date, blocks,
                           participants, top_oparticipant, top_opblocks, top_yparticipant, top_ypblocks,
                           teams, top_oteam, top_otblocks, top_yteam, top_ytblocks)
select 
  (select max(date) from RC5_64_master) as date,
  (select sum(blocks) from RC5_64_master where date = (select max(date) from RC5_64_master)) as blocks,
  (select count(*) from RC5_64_master where date = (select max(date) from RC5_64_master)) as participants,
  (select id from stats.statproc.CACHE_em_RANK where Rank = 1) as top_oparticpant,
  (select blocks from stats.statproc.CACHE_em_RANK where Rank = 1) as top_opblocks,
  (select id from stats.statproc.CACHE_em_YRANK where Rank = 1) as top_yparticpant,
  (select blocks from stats.statproc.CACHE_em_YRANK where Rank = 1) as top_ypblocks,
  (select count(team) from stats.statproc.CACHE_tm_YRANK) as teams,
  (select team from stats.statproc.CACHE_tm_RANK where Rank = 1) as top_oteam,
  (select blocks from stats.statproc.CACHE_tm_RANK where Rank = 1) as top_otblocks,
  (select team from stats.statproc.CACHE_tm_YRANK where Rank = 1) as top_yteam,
  (select blocks from stats.statproc.CACHE_tm_YRANK where Rank = 1) as top_ytblocks
go

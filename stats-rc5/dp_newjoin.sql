# $Id: dp_newjoin.sql,v 1.1 1999/07/27 20:49:03 nugget Exp $

update RC5_64_master set team = (select team from STATS_participant where STATS_participant.id = RC5_64_master.id)
where (team = NULL or team = 0) and 
      (select team from STATS_participant where STATS_participant.id = RC5_64_master.id) <> 0 and
      (select team from STATS_participant where STATS_participant.id = RC5_64_master.id) <> NULL
go


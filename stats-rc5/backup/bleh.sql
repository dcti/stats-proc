select count(*) from RC5_64_master
where (team = NULL or team = 0) and 
      (select team from STATS_participant where STATS_participant.id = RC5_64_master.id) <> 0 and
      (select team from STATS_participant where STATS_participant.id = RC5_64_master.id) <> NULL
go


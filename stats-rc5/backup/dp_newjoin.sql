update RC5_64_master set team = (select team from STATS_participant where STATS_participant.id = RC5_64_master.id)
where (team = 0) and 
      (select team from STATS_participant where STATS_participant.id = RC5_64_master.id) <> 0 
go


use stats
go

update WORK_master set
id = (select id from STATS_participant where WORK_master.EMAIL = STATS_participant.EMAIL)
where id = NULL
go


use stats
go

update WORK_master set
id = (select id from STATS_participant where WORK_master.email = STATS_participant.email)
where id = NULL
go


print "!! Appending day's activity to master tables"
go

print "::  Appending into rc5_64_master"
go
insert into RC5_64_master (date, id, team, blocks)
select distinct
  d.timestamp as date,
  p.id,
  p.team,
  sum(d.size) as blocks
from RC5_64_daytable_master d, STATS_participant p
where p.email = d.email
group by timestamp, id, team
go

print ":: Appending into rc5_64_platform"
go
insert into RC5_64_platform (date, cpu, os, ver, blocks)
select distinct
  timestamp as date,
  cpu,
  os,
  ver,
  sum(size) as blocks
from RC5_64_daytable_platform
group by timestamp, cpu, os, ver
go


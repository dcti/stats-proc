print "!! Appending day's activity to master tables"
go

print ":: Min date in _daytable:"
select min(timestamp) from rc5_64_daytable_master
print ":: Max date in _daytable:"
select max(timestamp) from rc5_64_daytable_master
print ":: Rows in _daytable:"
select count(*) from rc5_64_daytable_master
go

-- print ":: Max date in _master:"
-- select max(date) from rc5_64_master
-- go
create table #DaySum (
	date		smalldatetime,
	id		int,
	credit_id	int,
	team		int,
	blocks		numeric(20,0)
)
print "::  Summarizing data"
go

insert into #DaySum (date, id, credit_id, team, blocks)
	select d.timestamp as date, p.id, max(retire_to), 0, sum(d.size)
	from RC5_64_daytable_master d, STATS_participant p
	where p.email = d.email
	group by timestamp, id

update #DaySum
	set credit_id = id
	where credit_id = 0

declare @mdv smalldatetime
select @mdv = max(date)
	from #DaySum
update #DaySum
	set team = tj.team_id
	from Team_Joins tj
	where #DaySum.credit_id = tj.id
		and tj.JOIN_DATE <= @mdv
		and (tj.LAST_DATE = null or tj.LAST_DATE >= @mdv)
go

print "::  Appending into rc5_64_master"
go
insert into RC5_64_master (date, id, team, blocks)
	select date, id, team, blocks
	from #DaySum
go

-- print ":: Max date in _master:"
-- select max(date) from rc5_64_master
-- go

print ":: Appending into rc5_64_platform"
go
insert into RC5_64_platform (date, cpu, os, ver, blocks)
select
  timestamp as date,
  cpu,
  os,
  ver,
  sum(size) as blocks
from RC5_64_daytable_platform
group by timestamp, cpu, os, ver
go
-- print ":: Max date in _platform"
-- select max(date) from rc5_64_platform
-- go

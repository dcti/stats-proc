print "!! Begin CACHE_tm_MEMBERS Build"
go

use stats
set flushmessage on
set rowcount 0
go

drop table PREBUILD_tm_MEMBERS
go

print "::  Creating PREBUILD_tm_MEMBERS table"
go

create table PREBUILD_tm_MEMBERS
(	id numeric (10,0),
	team int,
	first smalldatetime,
	last smalldatetime,
	blocks numeric (10,0)
)
go

print "::  Filling cache table with data (id,team,first,last,blocks)"
go
select
  id,
  team,
  min(date) as first,
  max(date) as last,
  sum(blocks) as blocks
into #RANKa
from RC5_64_master
where team > 0
group by team, id
go

print "::  Honoring all retire_to requests"
go
update #RANKa
  set R.id = P.retire_to
from #RANKa R, STATS_participant P
where P.retire_to > 0 and P.id = R.id
go

print ":: Populating PREBUILD_tm_MEMBERS table"
go
insert into PREBUILD_tm_MEMBERS
  (id,team,first,last,blocks)
select id, team, min(first), max(last), sum(blocks)
from #RANKa
group by team, id
go

print ":: Creating clustered index"
go
create clustered index main on PREBUILD_tm_MEMBERS(team,blocks) with fillfactor = 100
go

grant select on PREBUILD_tm_MEMBERS to public
go

drop table CACHE_tm_MEMBERS_old
go

sp_rename CACHE_tm_MEMBERS, CACHE_tm_MEMBERS_old
go

sp_rename PREBUILD_tm_MEMBERS, CACHE_tm_MEMBERS
go


print "!! Begin CACHE_tm_MEMBERS Build"
go

use stats
set rowcount 0
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
select distinct
  id,
  team,
  min(date) as first,
  max(date) as last,
  sum(blocks) as blocks
into #RANKa
from RC5_64_master
where team <> 0 and team <> NULL
group by id,team
go

print ":: Linking to participant data in cache_table b (retire_to)"
go

select C.id, C.team, C.first, C.last, C.blocks, S.retire_to
into #RANKb
from #RANKa C, STATS_participant S
where C.id = S.id
go

print "::  Honoring all retire_to requests"
go
update #RANKb
  set id = retire_to
where retire_to <> id and retire_to <> NULL and retire_to <> 0
go

print ":: Populating PREBUILD_tm_MEMBERS table"
go
insert into PREBUILD_tm_MEMBERS
  (id,team,first,last,blocks)
select distinct id, team, min(first), max(last), sum(blocks)
from #RANKb
group by id, team
go

print ":: Creating clustered index"
go
create clustered index main on PREBUILD_tm_MEMBERS(team,blocks)
go
print ":: Updating statistics"
go
update statistics PREBUILD_tm_MEMBERS
go

grant select on PREBUILD_tm_MEMBERS to public
go

drop table CACHE_tm_MEMBERS_old
go

sp_rename CACHE_tm_MEMBERS, CACHE_tm_MEMBERS_old
go

sp_rename PREBUILD_tm_MEMBERS, CACHE_tm_MEMBERS
go


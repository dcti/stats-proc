print "!! Creating CSC_CACHE_tm_MEMBERS"
go

use stats
set rowcount 0
go

while exists (select * from sysobjects where id = object_id('CSC_CACHE_tm_MEMBERS_old'))
	drop table CSC_CACHE_tm_MEMBERS_old
go

while exists (select * from sysobjects where id = object_id('CSC_CACHE_tm_MEMBERS'))
	EXEC sp_rename 'CSC_CACHE_tm_MEMBERS', 'CSC_CACHE_tm_MEMBERS_old'
go

print "::  Creating CSC_CACHE_tm_MEMBERS table"
go

select distinct team, id, sum(blocks) as blocks
into CSC_CACHE_tm_MEMBERS
from CSC_master
group by team, id
go

print "::  Indexing CSC_CACHE_tm_MEMBERS"
create index team on CSC_CACHE_tm_MEMBERS(team)
go

grant select on CSC_CACHE_tm_MEMBERS to public
go


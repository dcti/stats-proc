# $Id: dp_tm_prepare.sql,v 1.1 1999/07/27 20:49:03 nugget Exp $

print "!! Creating CACHE_tm_MEMBERS"
go

use stats
set rowcount 0
go

while exists (select * from sysobjects where id = object_id('CACHE_tm_MEMBERS_old'))
	drop table CACHE_tm_MEMBERS_old
go

while exists (select * from sysobjects where id = object_id('CACHE_tm_MEMBERS'))
	EXEC sp_rename 'CACHE_tm_MEMBERS', 'CACHE_tm_MEMBERS_old'
go

print "::  Creating CACHE_tm_MEMBERS table"
go

select distinct team, id, sum(blocks) as blocks
into CACHE_tm_MEMBERS
from RC5_64_master
group by team, id
go

print "::  Indexing CACHE_tm_MEMBERS"
create index team on CACHE_tm_MEMBERS(team)
go

grant select on CACHE_tm_MEMBERS to public
go


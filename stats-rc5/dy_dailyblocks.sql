# $Id: dy_dailyblocks.sql,v 1.1 1999/07/27 20:49:03 nugget Exp $

drop table CACHE_dailyblocks
go

create table CACHE_dailyblocks
(
  date smalldatetime,
  blocks numeric(12,0)
)
go

insert into CACHE_dailyblocks (date, blocks)
select distinct date, sum(blocks)
from RC5_64_master
group by date
order by date
go

create index date on CACHE_dailyblocks(date)
go

grant select on CACHE_dailyblocks to public
go

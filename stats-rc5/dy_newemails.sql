# $Id: dy_newemails.sql,v 1.1 1999/07/27 20:49:04 nugget Exp $

select distinct email, NULL as id
into #newemails
from RC5_64_daytable_master
group by email
go

update #newemails
set id = (select id from STATS_participant S where S.email = #newemails.email)
go

delete from #newemails where id <> NULL
go

insert into STATS_participant (email)
select email from #newemails
go


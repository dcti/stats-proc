-- $Id: stats.sql,v 1.1 2003/03/20 18:40:09 nerf Exp $

select now();

BEGIN;

delete from ogr_stats
where  table_name = 'ogr_stubs'
and function = 'count';

insert into ogr_stats (table_name,function,result,project_id)
select 'ogr_stubs','count',count(*),project_id
from ogr_stubs
group by project_id;

select now();


delete from ogr_stats
where function = 'pass1';

insert into ogr_stats (function,result,project_id)
select 'pass1',count(distinct su.stub_id),project_id
from ogr_stubs s, ogr_summary su
where s.stub_id = su.stub_id
group by project_id;

select now();

delete from ogr_stats
where function = 'pass2';

insert into ogr_stats (function,result,project_id)
select 'pass2',count(distinct su.stub_id),project_id
from ogr_stubs s, ogr_summary su
where s.stub_id = su.stub_id
	and su.max_client >= 8014
	and su.participants >=2
group by project_id;

COMMIT;
select now();


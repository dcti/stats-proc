-- $Id: stats.sql,v 1.6 2003/07/21 00:19:44 nerf Exp $

CREATE TABLE public.ogr_complete (
	rundate date DEFAULT ('now'::text)::date NOT NULL,
	project_id int2 NOT NULL,
	count int4 NOT NULL,
	pass1 int4 NOT NULL,
	pass2 int4 NOT NULL,
	CONSTRAINT ogr_complete_pkey PRIMARY KEY (rundate, project_id)
) WITHOUT OIDS;

\set ON_ERROR_STOP 1

CREATE TEMP TABLE ogr_stats (
  table_name varchar(22), 
  function varchar(12), 
  result int8, 
  project_id int2
) WITHOUT OIDS;

select now();

BEGIN;


insert into ogr_stats (table_name,function,result,project_id)
select 'ogr_stubs','count',count(*),project_id
from ogr_stubs
group by project_id;

insert into ogr_stats (function,result,project_id)
select 'pass1',count(distinct su.stub_id),project_id
from ogr_stubs s, ogr_summary su
where s.stub_id = su.stub_id
group by project_id;

insert into ogr_stats (function,result,project_id)
select 'pass2',count(distinct su.stub_id),project_id
from ogr_stubs s, ogr_summary su
where s.stub_id = su.stub_id
	and su.max_client >= 8014
	and su.participants >=2
group by project_id;

analyze ogr_stats;

INSERT INTO ogr_complete
SELECT :RUNDATE as rundate,Cnt.project_id, Cnt.result as count, 
        P1.result as Pass1, P2.result as Pass2
FROM ogr_stats as Cnt, ogr_stats as P1, ogr_stats as P2 
WHERE Cnt.function = 'count' AND P1.function = 'pass1'
AND P2.function = 'pass2' AND Cnt.project_id = P1.project_id 
AND P1.project_id = P2.project_id;

COMMIT;

select now();

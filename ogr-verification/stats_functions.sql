-- $Id: stats_functions.sql,v 1.3 2004/04/14 15:25:31 nerf Exp $
-- Functions/procedures used for OGR stats processing

CREATE OR REPLACE FUNCTION doOGRstatsrun(date) returns int as '
DECLARE
my_counter int DEFAULT 0;
my_rundate alias for $1;
BEGIN
  FOR project_id IN 24..25 LOOP
    perform get_OGRstats(my_rundate,project_id) ;
    my_counter := my_counter + 1 ;
  END LOOP;
  return my_counter;
END; '  LANGUAGE 'plpgsql' ;

CREATE OR REPLACE FUNCTION getCount(integer) returns integer as '
DECLARE
f_project_id ALIAS for $1;
my_count integer;
BEGIN
  IF f_project_id = 24 THEN
    return 5364870;
  ELSIF f_project_id = 25 THEN 
    return 20879063;
  ELSE
    --default
    select count(*) into my_count
    FROM OGR_stubs s
    WHERE s.project_id = f_project_id;

    IF my_count IS NULL THEN
      return 0;
    ELSE
      return my_count;
    END IF;
  END IF;
END; '  LANGUAGE 'plpgsql' ;

CREATE OR REPLACE FUNCTION get_OGRstats(date,integer) returns float as '
DECLARE
my_rundate ALIAS for $1;
f_project_id ALIAS for $2;
f_count integer;
f_pass1 integer;
f_pass2 integer;
f_stubs_returned integer;
f_in_complete integer;
BEGIN

select into f_count getCount(f_project_id);

select into f_pass1 count(distinct stub_id)
from ogr_summary
where project_id = f_project_id;

select into f_pass2 count(distinct stub_id)
from ogr_summary
where max_client >= 8014
  and participants >=2
AND project_id = f_project_id;

select into f_stubs_returned count(*)
from logdata ly, ogr_stubs s
where ly.stub_marks = s.stub_marks
AND project_id = f_project_id;

select count(*) into f_in_complete
FROM OGR_complete c
WHERE c.project_id = f_project_id
AND c.rundate = my_rundate;

IF f_in_complete > 0 THEN
  RAISE WARNING ''OGR-VER: Stats for rundate % already exist!'', my_rundate;
  RAISE WARNING ''OGR-VER: project_id = %'', f_project_id;
  RAISE WARNING ''OGR-VER: Check to see if this run has already been done'';
  RETURN NULL;
END IF;

INSERT INTO ogr_complete (rundate,project_id,count,pass1,pass2,stubs_returned)
values (my_rundate,f_project_id, f_count, f_pass1, f_pass2, f_stubs_returned);

RETURN (f_pass2::float/f_count::float)::float;

END; '  LANGUAGE 'plpgsql' ;

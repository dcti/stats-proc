-- $Id --

insert into nodes
select distinct email , stub_id , nodecount, os_type, cpu_type, version
from logdata;

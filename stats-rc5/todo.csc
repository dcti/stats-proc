daily.pl:
Change it to import all contests, then call the ranking, etc.

clearimport.sql: No changes needed.

cleardaytable.sql:
Add contest ID field to both tables

dy_integrate.sql:
Add contest ID field to both tables

dy_fixemails.sql: No changes needed.

dy_newemails.sql: No changes needed.

dy_appendday.sql:
Add contest ID to both queries. Also, if we want to start tracking CPU, etc. 
per participant, now is the time to do it...(this will affect some of the above too).

dp_newjoin.sql: No changes needed.

dp_em_rank.sql:
Awwwww, fuck. I forgot all about
'update CACHE_em_RANK
  set rank = idx,'
This sucks, because I don't know of a way to handle multiple contests very easily that way. We'll need to
do this part using a temptable for each contest, then roll the temp tables back into one. Weee!

create table CACHE_em_RANK: add contest id field
select into #RANKa: add contest id, change group by to 'group by contest_id, id'
select into #RANKb: add contest_id to the select clause
retire_to: No changes needed.
insert into CACHE_em_RANK: add contest_id to select and insert, change group by to 'group by contest_id, id'
*I'm stopping on this file here, for the time being*

dp_em_yrank.sql:
This looks to be the exact same as dp_em_rank.sql.

dp_members.sql:
create table PREBUILD_tm_MEMBERS: add contest_id
insert into #RANKa: add contest_id to insert and select, change group by to 'group by contest_id, id, team'
select into #RANKb: add contest_id
insert into PREBUILD_tm_MEMBERS: add contest_id to insert and select, change group by to 'group by contest_id, id, team'

dp_tm_rank.sql:
Same deal as dp_em_rank, plus there's a hell of a lot of shit going on in there which I have to wonder if it's
needed. There's like 4 queries dealing with calculating how many members there are, which we should be able
to find easily from tm_members.

dp_tm_yrank.sql:
Looks very similar to dp_tm_rank.sql.

dy_dailyblocks.sql:
Add contest_id where appropriate. We'll probably want a master contest id table to query off of for this.

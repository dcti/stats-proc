#!/usr/bin/sqsh -i
#
# $Id: dy_newemails.sql,v 1.3 2000/02/21 03:47:06 bwilson Exp $
#
# Adds new participants to stats_participant
#
# Arguments:
#       Project

print "!! Adding new emails to stats_participant"
go
print "::  Creating temp table with identity"
go
create table #dayemails
(
	id		numeric(10, 0)	identity,
	email		varchar(64)	not NULL
)
go

print "::  Inserting all new emails from daytable"
go
select distinct email
	into #allemails
	from ${1}_daytable_master
	where email <> 'rc5@distributed.net'
		and email <> 'rc5-bad@distributed.net'
	order by email
/*
**	Eliminate all the rc5@d.net and rc5-bad@d.net rows on the first pass
**	We know this id exists, so don't clutter up the temp tables
**	grouping them together.
*/
go
create unique clustered index iemail on #allemails(email) with sorted_data
go

delete #allemails
	from STATS_Participant
	where #allemails.email = STATS_Participant.email
go

insert into #dayemails (email)
	select email
	from #allemails
go

print "::  Adding new participants to stats_participant"
go
declare @idoffset int

select @idoffset = max(id)
	from STATS_Participant
	where id < 5000000

-- [BW] If we switch to retire_to = id as the normal condition,
--	this insert should insert (id, email, retire_to)
--	from id + @idoffset, email, id + @idoffset
insert into STATS_participant (id, email)
	select id + @idoffset, email
	from #dayemails
go
drop table #dayemails
drop table #allemails
go

#!/usr/bin/sqsh -i
#
# $Id: newjoin.sql,v 1.4 2000/11/08 15:00:26 decibel Exp $
#
# Assigns old work to current team
#
# Arguments:
#       PROJECT_ID

set flushmessage on
print ":: Assigning old work to current team"
go

#-- This query will only get joins to teams (not to team 0) that have
#-- taken place on the day that we're running stats for.
declare @proj_date smalldatetime
select @proj_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

select id, team_id
	into #newjoins
	from Team_Joins
	where JOIN_DATE = @proj_date
		and (LAST_DATE = NULL or LAST_DATE >= @proj_date)
go

-- Dont forget to check for any retired emails that have blocks on team 0
declare ids cursor for
	select distinct sp.id, sp.retire_to, nj.team_id
	from STATS_Participant sp, #newjoins nj
	where sp.id = nj.id
		or (sp.retire_to = nj.id and sp.retire_to > 0)
go

begin transaction
declare @id int, @retire_to int, @team_id int
declare @work numeric(20,0), @first smalldatetime, @last smalldatetime
declare @eff_id int, @curfirst smalldatetime, @curlast smalldatetime
declare @update_ids int, @total_ids int, @idrows int, @total_rows int
select @update_ids = 0, @total_ids = 0, @total_rows = 0
open ids
fetch ids into @id, @retire_to, @team_id

while (@@sqlstatus = 0)
begin
# first, see if there's any work for this participant
	select @work = sum(WORK_UNITS), @first = min(DATE), @last = max(DATE)
		from Email_Contrib
		where ID = @id
			and PROJECT_ID = ${1}
			and TEAM_ID = 0

# Don't do the update if there's no work for this person
	if @work > 0
	begin

# Update Email_Contrib
		update Email_Contrib set Email_Contrib.TEAM_ID = @team_id
			where ID = @id
				and PROJECT_ID = ${1}
				and TEAM_ID = 0
	
		select @update_ids = @update_ids + 1, @idrows = @@rowcount, @total_rows = @total_rows + @@rowcount

# Update Team_Members
		if @retire_to = 0
			select @eff_id = @id
		else
			select @eff_id = @retire_to

		select @curfirst = FIRST_DATE, @curlast = LAST_DATE
			from Team_Members
			where ID = @eff_id
				and PROJECT_ID = ${1}
				and TEAM_ID = @team_id

		-- See if we need to update first and last dates
		if @curfirst > @first
			select @curfirst = @first
		if @curlast < @last
			select @curlast = @first

		update Team_Members
			set WORK_TOTAL = WORK_TOTAL + @work,
				FIRST_DATE = @curfirst,
				LAST_DATE = @curlast
			where ID = @eff_id
				and PROJECT_ID = ${1}
				and TEAM_ID = @team_id

# Update Team_Rank
		select @curfirst = FIRST_DATE, @curlast = LAST_DATE
			from Team_Rank
			where PROJECT_ID = ${1}
				and TEAM_ID = @team_id

		-- See if we need to update first and last dates
		if @curfirst > @first
			select @curfirst = @first
		if @curlast < @last
			select @curlast = @first

		update Team_Rank
			set WORK_TOTAL = WORK_TOTAL + @work,
				FIRST_DATE = @curfirst,
				LAST_DATE = @curlast
			where PROJECT_ID = ${1}
				and TEAM_ID = @team_id

		print "  %1! rows processed for ID %2!, TEAM_ID %3!", @idrows, @id, @team_id
	end

	select @total_ids = @total_ids + 1
	fetch ids into @id, @retire_to, @team_id
end

if (@@sqlstatus = 1)
	print "ERROR! Cursor returned an error"

close ids
deallocate cursor ids
print "%1! of %2! IDs updated; %3! rows total", @update_ids, @total_ids, @total_rows
commit transaction
go -f


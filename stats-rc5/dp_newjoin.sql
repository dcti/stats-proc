declare @mdv smalldatetime
select @mdv = max(date)
from RC5_64_master

-- This query will only get joins to teams (not to team 0) that have
-- taken place on the day that we're running stats for.
select id, team_id
	into #newjoins
	from Team_Joins
	where JOIN_DATE = @mdv
		and (LAST_DATE = NULL or LAST_DATE >= @mdv)
go

-- We need to check for any retired emails that have blocks on team 0
declare ids cursor for
	select distinct sp.id, nj.team_id
	from STATS_Participant sp, #newjoins nj
	where sp.id = nj.id
		or (sp.retire_to = nj.id and sp.retire_to > 0)
go

declare @id int, @team_id int
declare @totalids int, @idrows int, @totalrows int
select @totalids = 0, @totalrows = 0
open ids
fetch ids into @id, @team_id

while (@@sqlstatus = 0)
begin
	update RC5_64_master set RC5_64_master.team = @team_id
		where RC5_64_master.id = @id
			and RC5_64_master.team = 0

	select @totalids = @totalids + 1, @idrows = @@rowcount, @totalrows = @totalrows + @@rowcount
	print "  %1! rows processed for ID %2!, TEAM_ID %3!", @idrows, @id, @team_id

	fetch ids into @id, @team_id
end

if (@@sqlstatus = 1)
	print "ERROR! Cursor returned an error"

close ids
deallocate cursor ids
print "%1! IDs processed; %2! rows total", @totalids, @totalrows
go -f

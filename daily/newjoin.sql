#!/usr/bin/sqsh -i
#
# $Id: newjoin.sql,v 1.13.2.1 2003/04/15 04:24:12 decibel Exp $
#
# Assigns old work to current team
#
# Arguments:
#       ProjectID

\echo :: Assigning old work to current team
;

#-- This query will only get joins to teams (not to team 0) that have
#-- taken place on the day that we're running stats for.
select id, team_id
	into TEMP newjoins
	from Team_Joins tj, Project_statsrun ps
	where tj.join_date = ps.last_hourly_date
		and (last_date = NULL or last_date >= ps.last_hourly_date)
;

select sp.id, sp.retire_to, nj.team_id
	into TEMP nj_ids
	from STATS_Participant sp, newjoins nj
	where sp.retire_to = nj.id
		and sp.retire_to > 0
		and nj.id > 0
;

insert into nj_ids (id, retire_to, team_id)
	select sp.id, 0, nj.team_id
	from STATS_Participant sp, newjoins nj
	where sp.id = nj.id
;

UPDATE Email_Contrib
    SET team_id = nj.team_id
    FROM nj_ids nj
    WHERE Email_Contrib.project_id = :ProjectID
        AND Email_Contrib.id = nj.id
        AND Email_Contrib.team_id = 0
;

declare @id int, @retire_to int, @team_id int
declare @work numeric(20,0), @first smalldatetime, @last smalldatetime
declare @eff_id int, @curfirst smalldatetime, @curlast smalldatetime, @rank int
declare @abort tinyint, @update_ids int, @total_ids int, @idrows int, @total_rows int
select @update_ids = 0, @total_ids = 0, @total_rows = 0
open ids
fetch ids into @id, @retire_to, @team_id

while (@@sqlstatus = 0)
begin
# first, see if there's any work for this participant
	select @work = sum(WORK_UNITS), @first = min(DATE), @last = max(DATE)
		from Email_Contrib
		where ID = @id
			and PROJECT_ID = :ProjectID
			and TEAM_ID = 0

# Don't do the update if there's no work for this person
	if @work > 0
	begin
		select @abort = 0
		begin transaction

# Update Email_Contrib
		update Email_Contrib set Email_Contrib.TEAM_ID = @team_id
			where ID = @id
				and PROJECT_ID = :ProjectID
				and TEAM_ID = 0
	
		select @abort = @abort + sign(@@error), @update_ids = @update_ids + 1,
			@idrows = @@rowcount, @total_rows = @total_rows + @@rowcount

# Update Team_Members
		if @retire_to = 0
			select @eff_id = @id
		else
			select @eff_id = @retire_to

		if exists (select * from Team_Members where ID = @eff_id and PROJECT_ID = :ProjectID and TEAM_ID = @team_id)
		begin
			select @curfirst = FIRST_DATE, @curlast = LAST_DATE
				from Team_Members
				where ID = @eff_id
					and PROJECT_ID = :ProjectID
					and TEAM_ID = @team_id
	
			-- See if we need to update first and last dates
			if @curfirst > @first
				select @curfirst = @first
			if @curlast < @last
				select @curlast = @last

			update Team_Members
				set WORK_TOTAL = WORK_TOTAL + @work,
					FIRST_DATE = @curfirst,
					LAST_DATE = @curlast
				where ID = @eff_id
					and PROJECT_ID = :ProjectID
					and TEAM_ID = @team_id
			
			select @abort = @abort + sign(@@error)
		end
		else
		begin
			select @rank = count(*) from Team_Members where PROJECT_ID = :ProjectID and TEAM_ID = @team_id
			insert Team_Members (PROJECT_ID, ID, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_TODAY, WORK_TOTAL,
					DAY_RANK, DAY_RANK_PREVIOUS, OVERALL_RANK, OVERALL_RANK_PREVIOUS)
				values ( :ProjectID, @eff_id, @team_id, @first, @last, 0, @work,
					@rank, 0, @rank, 0 )
			
			if @@error > 0
				select @abort = @abort + 1
		end
# Update Team_Rank
		if exists (select * from Team_Rank where PROJECT_ID = :ProjectID and TEAM_ID = @team_id)
		begin
			select @curfirst = FIRST_DATE, @curlast = LAST_DATE
				from Team_Rank
				where PROJECT_ID = :ProjectID
					and TEAM_ID = @team_id
	
			-- See if we need to update first and last dates
			if @curfirst > @first
				select @curfirst = @first
			if @curlast < @last
				select @curlast = @first
	
			update Team_Rank
				set WORK_TOTAL = WORK_TOTAL + @work,
					FIRST_DATE = @curfirst,
					LAST_DATE = @curlast,
					MEMBERS_OVERALL = MEMBERS_OVERALL + 1,
					MEMBERS_CURRENT = MEMBERS_CURRENT + 1
				where PROJECT_ID = :ProjectID
					and TEAM_ID = @team_id
			
			select @abort = @abort + sign(@@error)
		end
		else
		begin
			select @rank = count(*) + 1 from Team_Rank where PROJECT_ID = :ProjectID
			insert Team_Rank (PROJECT_ID, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_TODAY, WORK_TOTAL,
					DAY_RANK, DAY_RANK_PREVIOUS, OVERALL_RANK, OVERALL_RANK_PREVIOUS,
					MEMBERS_TODAY, MEMBERS_OVERALL, MEMBERS_CURRENT)
			values ( :ProjectID, @team_id, @first, @last, 0, @work,
				@rank, 0, @rank, 0, 0, 0, 0 )
			
			select @abort = @abort + sign(@@error)
		end

# Commit (or rollback)
		if @abort = 0
			commit transaction
		else
		begin
			\echo %1! error(s) encountered, rolling back transaction!, @abort
			rollback transaction
		end

		\echo   %1! rows processed for ID %2!, TEAM_ID %3!, @idrows, @id, @team_id
	end

	select @total_ids = @total_ids + 1
	fetch ids into @id, @retire_to, @team_id
end

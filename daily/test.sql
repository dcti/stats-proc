if object_id(\\'PREBUILT_${1}_CACHE_em_RANK\\') is not NULL
        if exists (select * from PREBUILT_${1}_CACHE_em_RANK)
        begin
                -- Do a select into instead of a rename so that the stored procs don't keep hitting
                -- the old table
                select * into ${1}_CACHE_em_RANK_backup from ${1}_CACHE_em_RANK
                revoke select on ${1}_CACHE_em_RANK to public
--                drop table ${1}_CACHE_em_RANK
--               EXEC sp_rename "PREBUILT_${1}_CACHE_em_RANK", "${1}_CACHE_em_RANK"
        end
go

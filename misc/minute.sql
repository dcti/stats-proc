-- If update doesn't run, there's no sense in trying for the delete
DELETE
    FROM page_log.log
    WHERE (SELECT rrs.update()) >= 0
        AND log_time < (SELECT min(last_end_time)
                            FROM rrs.source s
                                JOIN rrs.source_status ss USING (source_id)
                            WHERE source_name = 'page_log'
                        )
;

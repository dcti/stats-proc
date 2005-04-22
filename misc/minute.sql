-- If update doesn't run, there's no sense in trying for the delete
DELETE
    FROM page_log.log
    WHERE (SELECT rrs.update()) >= 0
        AND log_time < (SELECT min(coalesce(last_end_time, '1970-01-01 00:00:00-00'))
                            FROM rrs.source s
                                JOIN rrs.rrs r ON ( 1 = 1 )
                                LEFT JOIN rrs.source_status ss ON (s.source_id = ss.source_id
                                                                    AND r.rrs_id = ss.rrs_id)
                            WHERE source_name = 'page_log'
                                AND parent IS NULL
                        )
;

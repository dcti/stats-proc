-- $Id: import_r72_logs.sql,v 1.2 2005/02/16 21:03:22 decibel Exp $

TRUNCATE TABLE import;

COPY import_logs(return_time, ip_address, email, key_block, iter, os_type, cpu_type, version, core, cmc_last, cmc_count, cmc_ok)
    FROM :IMPORTFILE DELIMITER ','
;

-- vi:expandtab sw=4 ts=4 nobackup

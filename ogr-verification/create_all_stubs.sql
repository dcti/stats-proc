-- $Id: create_all_stubs.sql,v 1.1 2002/12/24 22:26:41 nerf Exp $

CREATE SEQUENCE stub_id START 1;

CREATE TEMPORARY TABLE all_stubs_import (
stub_marks VARCHAR(22) not null);

COPY all_stubs_import FROM '/home/nerf/all_stubs';

CREATE TABLE all_stubs (
stub_marks VARCHAR(22) not null,
stub_id INT DEFAULT NEXTVAL('stub_id') not null,
completed INT DEFAULT 0);

INSERT INTO all_stubs
        SELECT stub_marks, NEXTVAL('stub_id'), 0
FROM all_stubs_import;

--DROP TABLE all_stubs_import;

CREATE INDEX all_marks ON all_stubs (stub_marks);
ALTER TABLE all_stubs ADD PRIMARY KEY (stub_id);

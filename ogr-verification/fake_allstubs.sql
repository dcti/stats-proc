-- $Id: fake_allstubs.sql,v 1.6 2003/05/13 14:05:42 nerf Exp $
\set ON_ERROR_STOP 1

-- Create a fake all_stubs table for people who don't have access to
-- the real one

CREATE SEQUENCE stub_id START 1;

CREATE TABLE OGR_stubs (
stub_marks VARCHAR(22) not null,
stub_id INT DEFAULT NEXTVAL('stub_id') not null,
completed INT DEFAULT 0);

INSERT INTO TABLE OGR_stubs
        SELECT DISTINCT stub_marks,
                nextval('stub_id') AS stub_id, 0 AS completed
        FROM logdata;

ALTER TABLE OGR_stubs ADD PRIMARY KEY (stub_id);
CREATE INDEX all_marks ON OGR_stubs (stub_marks);
CREATE INDEX all_completed ON OGR_stubs (completed);

-- $Id: fake_allstubs.sql,v 1.4 2002/12/24 22:22:02 nerf Exp $

-- Create a fake all_stubs table for people who don't have access to
-- the real one

CREATE SEQUENCE stub_id START 1;

CREATE TABLE all_stubs (
stub_marks VARCHAR(22) not null,
stub_id INT DEFAULT NEXTVAL('stub_id') not null,
completed INT DEFAULT 0);

INSERT INTO TABLE all_stubs
        SELECT DISTINCT stub_marks,
                nextval('stub_id') AS stub_id, 0 AS completed
        FROM logdata;

ALTER TABLE all_stubs ADD PRIMARY KEY (stub_id);
CREATE INDEX all_marks ON all_stubs (stub_marks);
CREATE INDEX all_completed ON all_stubs (completed);

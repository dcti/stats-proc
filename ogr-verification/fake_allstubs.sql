-- $Id: fake_allstubs.sql,v 1.1 2002/12/23 18:19:16 nerf Exp $

-- Create a fake all_stubs table for people who don't have access to
-- the real one

CREATE SEQUENCE stub_id START 1;

CREATE TABLE all_stubs AS
        SELECT stub_id AS stub_marks,
                nextval('stub_id') AS stub_id, 0 AS completed
        FROM nodes 
        GROUP BY nodes.stub_id;

CREATE INDEX all_marks ON all_stubs (stub_marks);
CREATE INDEX all_id ON all_stubs (stub_id);
CREATE INDEX all_completed ON all_stubs (completed);

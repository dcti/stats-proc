-- $Id: create_cheaters.sql,v 1.2 2002/12/23 13:40:45 nerf Exp $
-- Create a table where we keep track of how many stubs someone has
-- returned vs how many unique ones they have returned.  Used to find
-- people who submit the same stub over and over.

INSERT INTO TABLE cheaters
	SELECT id, count(stub_id) AS returned,
	count(DISTINCT stub_id) AS uniq_stubs
FROM logdata
GROUP BY id;

CREATE TABLE new_cheaters AS
	SELECT * FROM cheaters 
	GROUP BY id;

COMMIT;

DELETE * FROM cheaters;

INSERT INTO TABLE cheaters
	SELECT * FROM new_cheaters;

COMMIT;

DROP TABLE new_cheaters;

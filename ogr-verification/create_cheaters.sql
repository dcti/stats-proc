-- $Id: create_cheaters.sql,v 1.9 2003/05/13 14:05:42 nerf Exp $
-- Create a table where we keep track of how many stubs someone has
-- returned vs how many unique ones they have returned.  Used to find
-- people who submit the same stub over and over.
\set ON_ERROR_STOP 1

CREATE TABLE cheaters (
id INT NOT NULL,
returned INT,
uniq_stubs INT);

INSERT INTO cheaters
	SELECT I.id, count(A.stub_id) AS returned,
		count(DISTINCT A.stub_id) AS uniq_stubs
	FROM logdata L, OGR_idlookup I, OGR_stubs S
	WHERE lower(L.email) = lower(I.email) AND
		L.stub_marks = S.stub_marks
	GROUP BY id;

CREATE new_cheaters AS
	SELECT * FROM cheaters 
	GROUP BY id;

DELETE * FROM cheaters;

INSERT INTO TABLE cheaters
	SELECT * FROM new_cheaters;

DROP TABLE new_cheaters;

-- $Id: create_cheaters.sql,v 1.8 2003/02/16 19:18:42 nerf Exp $
-- Create a table where we keep track of how many stubs someone has
-- returned vs how many unique ones they have returned.  Used to find
-- people who submit the same stub over and over.

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

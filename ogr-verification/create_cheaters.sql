-- $Id: create_cheaters.sql,v 1.3 2002/12/24 21:54:14 nerf Exp $
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
	FROM logdata L, id_lookup I, all_stubs A
	WHERE L.email = I.email AND
		L.stub_marks = A.stub_id
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

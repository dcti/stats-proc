-- $Id: create_cheaters.sql,v 1.5 2003/01/01 17:01:05 joel Exp $
-- Create a table where we keep track of how many stubs someone has
-- returned vs how many unique ones they have returned.  Used to find
-- people who submit the same stub over and over.

CREATE TABLE cheaters:projnum (
id INT NOT NULL,
returned INT,
uniq_stubs INT);

INSERT INTO cheaters:projnum
	SELECT I.id, count(A.stub_id) AS returned,
		count(DISTINCT A.stub_id) AS uniq_stubs
	FROM logdata:projnum L, id_lookup I, all_stubs:projnum A
	WHERE L.email = I.email AND
		L.stub_marks = A.stub_id
	GROUP BY id;

CREATE new_cheaters:projnum AS
	SELECT * FROM cheaters:projnum 
	GROUP BY id;

DELETE * FROM cheaters:projnum ;

INSERT INTO TABLE cheaters:projnum
	SELECT * FROM new_cheaters:projnum ;

DROP TABLE new_cheaters:projnum ;

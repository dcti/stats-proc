-- $Id: initial_db.sql,v 1.1 2004/08/15 18:36:12 nerf Exp $

CREATE TABLE master (
	return_time	timestamp NOT NULL,
	ip_address	inet NOT NULL,
	participant_id	integer NOT NULL,
	stub_id		integer,
	nodecount	bigint,
	platform	integer NOT NULL,
	key_block	charactervarying(20),
	iter		integer,
	cmclast		charactervarying(20),
	cmccount	integer,
	cmcok		smallint,
	core		smallint,
	status		smallint,
	project_id	integer
);

-- $Id: initial_db.sql,v 1.2 2005/02/16 21:03:22 decibel Exp $

CREATE TABLE log (
	return_time		timestamp NOT NULL
	, ip_address		inet NOT NULL
	, participant_id	integer NOT NULL
	, platform		integer NOT NULL
	, project_id		integer NOT NULL
	, ogr_stub_id		integer
	, iter			integer
	, cmc_count		integer
	, cmc_ok		smallint
	, core			smallint
	, status		smallint
	, nodecount		bigint
	, key_block		charactervarying(20)
	, cmc_last		charactervarying(20)
) WITHOUT OIDs;

CREATE TABLE import (
	return_time	timestamp NOT NULL
	, ip_address	inet NOT NULL
	, email		charactervarying(64) NOT NULL
	, os_type	integer NOT NULL
	, cpu_type	integer NOT NULL
	, version	integer NOT NULL
	, stub_marks	charactervarying(22)
	, nodecount	bigint
	, status	smallint
	, key_block	charactervarying(20)
	, iter		integer
	, core		integer
	, cmc_last	charactervarying(20)
	, cmc_count	integer
	, cmc_ok		smallint
) WITHOUT OIDs;

-- vi: noexpandtab ts=8 sw=8

-- $Id: initial_db.sql,v 1.3 2005/02/16 21:10:01 decibel Exp $

CREATE TABLE log (
	return_time		timestamp NOT NULL
	, ip_address		inet NOT NULL
	, email_id		integer NOT NULL
	, platform_id		integer NOT NULL
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

CREATE TABLE email (
	email_id	SERIAL 		CONSTRAINT email__pk PRIMARY KEY
	, email		varchar(64) 	NOT NULL CONSTRAINT email__email UNIQUE
) WITHOUT OIDs;

CREATE TABLE platform (
	platform_id	SERIAL 	CONSTRAINT platform__pk PRIMARY KEY
	, os		int	NOT NULL
	, cpu		int	NOT NULL
	, version	int	NOT NULL
	, CONSTRAINT platform__os_cpu_version UNIQUE
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

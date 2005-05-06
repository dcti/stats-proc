-- $Id: initial_db.sql,v 1.6 2005/05/06 20:19:07 nerf Exp $

CREATE TABLE email (
	email_id	serial 		PRIMARY KEY
	, email		varchar(64) 	NOT NULL UNIQUE
) WITHOUT OIDs;

CREATE TABLE platform (
	platform_id	serial 	PRIMARY KEY
	, os		int	NOT NULL
	, cpu		int	NOT NULL
	, version	int	NOT NULL
	, UNIQUE (os, cpu, version)
) WITHOUT OIDs;

CREATE TABLE ogr_stubs (
	ogr_stub_id		serial PRIMARY KEY
	, stub_marks	varchar(22) NOT NULL UNIQUE
) WITHOUT OIDS;

CREATE TABLE log_8 (
	return_time		timestamp NOT NULL
	, ip_address		inet NOT NULL
	, email_id		integer NOT NULL REFERENCES email
	, platform_id		integer NOT NULL REFERENCES platform
	, iter			smallint NOT NULL
	, cmc_count		integer
	, cmc_ok		smallint
	, core			smallint NOT NULL
	, key_block		varchar(20) NOT NULL
	, cmc_last		varchar(20)
) WITHOUT OIDs;

CREATE TABLE log_24 (
	return_time		timestamp NOT NULL
	, ip_address		inet NOT NULL
	, email_id		integer NOT NULL REFERENCES email
	, platform_id		integer NOT NULL REFERENCES platform
	, ogr_stub_id		integer NOT NULL REFERENCES ogr_stubs
	, nodecount		bigint NOT NULL
	, status		smallint
) WITHOUT OIDs;

CREATE TABLE log_25 (
	return_time		timestamp NOT NULL
	, ip_address		inet NOT NULL
	, email_id		integer NOT NULL REFERENCES email
	, platform_id		integer NOT NULL REFERENCES platform
	, ogr_stub_id		integer NOT NULL REFERENCES ogr_stubs
	, nodecount		bigint NOT NULL
	, status		smallint
) WITHOUT OIDs;

CREATE TABLE import_r72 (
	return_time	timestamp NOT NULL
	, ip_address	inet NOT NULL
	, email		varchar(64) NOT NULL
	, os_type	integer NOT NULL
	, cpu_type	integer NOT NULL
	, version	integer NOT NULL
	, key_block	varchar(20) NOT NULL
	, iter		smallint NOT NULL
	, core		integer NOT NULL
	, cmc_last	varchar(20)
	, cmc_count	integer
	, cmc_ok	smallint
) WITHOUT OIDs;

CREATE TABLE import_ogr (
	return_time	timestamp NOT NULL
	, ip_address	inet NOT NULL
	, email		varchar(64) NOT NULL
	, os_type	integer NOT NULL
	, cpu_type	integer NOT NULL
	, version	integer NOT NULL
	, stub_marks	varchar(22) NOT NULL
	, nodecount	bigint NOT NULL
	, status	smallint
) WITHOUT OIDs;

-- vi: noexpandtab ts=8 sw=8

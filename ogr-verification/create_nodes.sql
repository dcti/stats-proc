-- $Id: create_nodes.sql,v 1.2 2002/12/20 23:55:45 nerf Exp $ --

CREATE TABLE nodes (
email VARCHAR(64),
stub_id VARCHAR(22),
nodecount BIGINT,
os_type SMALLINT,
cpu_type SMALLINT,
version INT,);


CREATE INDEX nodes_email_idx on nodes (email);
CREATE INDEX nodes_nodecount_idx on nodes (nodecount);
CREATE INDEX nodes_stubid_idx on nodes (stub_id);

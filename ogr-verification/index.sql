-- $Id: index.sql,v 1.2 2002/12/20 23:55:45 nerf Exp $ --

CREATE INDEX nodes_email ON nodes(email);
CREATE INDEX nodes_stub_id ON nodes(stub_id);
CREATE INDEX nodes_nodecount ON nodes(nodecount);
CREATE INDEX nodes_os_type ON nodes(os_type);
CREATE INDEX nodes_cpu_type ON nodes(cpu_type);
CREATE INDEX nodes_version ON nodes(version);

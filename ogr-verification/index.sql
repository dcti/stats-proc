-- $Id: index.sql,v 1.4 2002/12/22 22:14:34 nerf Exp $ --

CREATE INDEX stubs_id ON stubs(id);
CREATE INDEX stubs_stub_id ON stubs(stub_id);
CREATE INDEX stubs_nodecount ON stubs(nodecount);
CREATE INDEX stubs_os_type ON stubs(os_type);
CREATE INDEX stubs_cpu_type ON stubs(cpu_type);
CREATE INDEX stubs_version ON stubs(version);

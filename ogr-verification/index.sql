-- $Id: index.sql,v 1.6 2002/12/25 01:04:20 nerf Exp $ --

-- All the indices

CREATE INDEX stubs_id ON stubs(id);
CREATE INDEX stubs_stub_id ON stubs(stub_id);
CREATE INDEX stubs_nodecount ON stubs(nodecount);
CREATE INDEX all_stubs_marks ON all_stubs(stub_marks);
ALTER TABLE all_stubs ADD PRIMARY KEY (stub_id);
CREATE INDEX done_participants ON donenodes(participants);
CREATE INDEX idlookup_id ON id_lookup (id);
CREATE INDEX idlookup_email_idx ON id_lookup (email);
CREATE INDEX log_email_idx ON logdata (email);
CREATE INDEX log_nodecount_idx ON logdata (nodecount);
CREATE INDEX log_stubmark_idx ON logdata (stub_marks);

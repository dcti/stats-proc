-- $Id: index.sql,v 1.9 2003/01/08 02:24:59 joel Exp $ --
-- All the indices

CREATE INDEX stubs_id_ON stubs:projnum (id);
CREATE INDEX stubs_stub_id_ON stubs:projnum (stub_id);
CREATE INDEX stubs_nodecount_ON stubs:projnum (nodecount);
CREATE INDEX all_stubs_marks_ON all_stubs:projnum (stub_marks);
ALTER TABLE all_stubsADD PRIMARY KEY (stub_id);
CREATE INDEX done_participantsON donestubs:projnum (participants);
CREATE INDEX idlookup_id ON id_lookup (id);
CREATE INDEX idlookup_email_idx ON id_lookup (email);
CREATE INDEX log_email_idx ON logdata(email);
CREATE INDEX log_nodecount_idx_ON logdata(nodecount);
CREATE INDEX log_stubmark_idx_ON logdata(stub_marks);

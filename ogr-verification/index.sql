-- $Id: index.sql,v 1.8 2003/01/01 17:01:05 joel Exp $ --
-- All the indices

CREATE INDEX stubs_id_:projnum ON stubs:projnum (id);
CREATE INDEX stubs_stub_id_:projnum ON stubs:projnum (stub_id);
CREATE INDEX stubs_nodecount_:projnum ON stubs:projnum (nodecount);
CREATE INDEX all_stubs_marks_:projnum ON all_stubs:projnum (stub_marks);
ALTER TABLE all_stubs:projnum ADD PRIMARY KEY (stub_id);
CREATE INDEX done_participants:projnum ON donestubs:projnum (participants);
CREATE INDEX idlookup_id ON id_lookup (id);
CREATE INDEX idlookup_email_idx ON id_lookup (email);
CREATE INDEX log_email_idx_:projnum ON logdata:projnum (email);
CREATE INDEX log_nodecount_idx_:projnum ON logdata:projnum (nodecount);
CREATE INDEX log_stubmark_idx_:projnum ON logdata:projnum (stub_marks);

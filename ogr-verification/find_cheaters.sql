-- $Id: find_cheaters.sql,v 1.4 2003/01/08 02:23:09 joel Exp $
-- this gives people who have returned over 100 stubs, and over half of
-- them were dupes.  Highly likely these people are cheaters.
-- Note that these two variable were chosen ad hoc.

SELECT L.email, C.returned, C.uniq_stubs
FROM cheaters C, id_lookup L
WHERE (C.returned/C.uniq_stubs) >2
	AND C.returned>100
ORDER BY (C.returned/C.uniq_stubs) DESC;

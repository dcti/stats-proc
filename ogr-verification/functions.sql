CREATE OR REPLACE FUNCTION table_exists( VARCHAR ) RETURNS BOOLEAN AS '
DECLARE
t_name ALIAS for $1;
t_result VARCHAR;
BEGIN
--find table, case-insensitive
	SELECT relname INTO t_result
		FROM pg_class
		WHERE relname ~* (''^'' || t_name || ''$'')
		AND relkind = ''r'';
	IF t_result IS NULL THEN
		RETURN FALSE;
	ELSE 
		RETURN TRUE;
	END IF;
END;
' LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION drop_table( NAME ) RETURNS BOOLEAN AS '
DECLARE
TableName ALIAS FOR $1;
T NAME;
BEGIN
	IF table_exists(TableName) THEN
		T := lower(TableName);
		EXECUTE ''DROP TABLE '' || quote_ident(T);
		RETURN TRUE;
	END IF;
	RETURN FALSE;
END;
' LANGUAGE 'plpgsql' WITH (isstrict);

CREATE OR REPLACE FUNCTION max(int4, int4) RETURNS int4 AS '
BEGIN
	IF $1 > $2 THEN
		RETURN $1;
	ELSE
		RETURN $2;
	END IF;
END;'  LANGUAGE 'plpgsql' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION min(int4, int4) RETURNS int4 AS '
BEGIN
	IF $1 < $2 THEN
		RETURN $1;
	ELSE
		RETURN $2;
	END IF;
END;'  LANGUAGE 'plpgsql' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION update_completed( VARCHAR, VARCHAR,DATE )
	RETURNS BOOLEAN AS '
DECLARE
t_table_from ALIAS for $1;
t_table_to ALIAS for $2;
t_date ALIAS for $3;
t_result VARCHAR;
BEGIN
	update ogr_completed
	set t_field =
	SELECT ogr_stats.t_field INTO t_result
		FROM pg_class
		WHERE relname ~* (''^'' || t_name || ''$'')
		AND relkind = ''r'';
	IF t_result IS NULL THEN
		RETURN FALSE;
	ELSE 
		RETURN TRUE;
	END IF;
END;
' LANGUAGE 'plpgsql';

-- Geometric mean
-- (similar to mean aka average, except that geometric 
-- mean reduces the effect of outliers). 
-- Calculated by x1 * x2 * x3 ... xn ^ ( 1 / n )
--
-- Written by Jeff Davis [list-pgsql-general@empires.org]
-- and Tom Lane [tgl@sss.pgh.pa.us]

create or replace function gmean_f1 (point, float) returns point as '
  begin 
    return point($1[0] * $2, $1[1] + 1); 
  end' language plpgsql;

create or replace function gmean_final (point) returns float as '
  begin 
    return ($1[0] ^ (1/($1[1]))); 
  end' language plpgsql;

create aggregate gmean(
  basetype=float, 
  sfunc=gmean_f1, 
  stype=point, 
  finalfunc=gmean_final, 
  initcond='1.0,0.0'
);

comment on aggregate gmean(float) is 'Geometric mean aggregate';

comment on function gmean_f1(point,float) is 'Geometric mean aggregate base function';

comment on function gmean_final(point) is 'Geometric mean aggregate final function';

CREATE OR REPLACE FUNCTION rows() RETURNS int4 AS '
DECLARE
	f_rowcount int4;
BEGIN
	perform distinct * from log_fix;
	GET DIAGNOSTICS f_rowcount = ROW_COUNT;
	RETURN f_rowcount;
END;'  LANGUAGE 'plpgsql' ;

CREATE or replace FUNCTION stublen (varchar(22)) RETURNS integer AS '
my ($stub_marks) = @_;

#just strip off the number of marks and get the marks into an array
my (@marks) = split (/-/ ,substr($stub_marks,3)) ;

my $stub_sum = 0;
foreach $mark (@marks) {
   $stub_sum += $mark
};

return $stub_sum;
 ' LANGUAGE 'plperl' IMMUTABLE STRICT;

CREATE or replace FUNCTION stublen (varchar(22),integer) RETURNS integer AS '
my ($stub_marks,$num_marks) = @_;

#just strip off the number of marks and get the marks into an array
my (@marks) = split (/-/ ,substr($stub_marks,3)) ;

if ($num_marks < @marks ) {
   $real_marks = $num_marks }
else {
   $real_marks = @marks }

my $stub_sum = 0;
foreach $index (0..($real_marks-1)) {
   $stub_sum += $marks[$index]
};

return $stub_sum;
 ' LANGUAGE 'plperl' IMMUTABLE STRICT;

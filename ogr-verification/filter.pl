#!/usr/bin/perl
# 11/28/2002 - Joel Von Holdt for distributed.net
# $Id: filter.pl,v 1.5 2002/12/27 22:33:52 joel Exp $

use strict;
my ( $var, $fn, $fn24, $fn25, $reject, $numargs, $i );
my ( $tasktime, $timenow, $timedone, $lines, $blocktime, $blockip, $email, $stub_id, $nodecount, $os_type, $cpu_type, $version, $core );

$timenow = time();

$fn24 = "ogr24.filtered";
$fn25 = "ogr25.filtered";
$reject = "rejects.filtered";

open (REJ, ">$reject") || die "Sorry, cant open reject output file. $! \n";
open (LOG24, ">$fn24") || die "Sorry, cant open ogr-24 output file. $! \n";
open (LOG25, ">$fn25") || die "Sorry, cant open ogr-25 output file. $! \n";

$numargs = @ARGV;

for($i=0;$i<$numargs;$i++) {

$var = @ARGV[$i];

	if (substr($var, -1, 1) == "2") {
        	system "bunzip2 $var";
        	$fn = substr($var, 0, -4);
	} elsif(substr($var, -1, 1) == "z") {
        	system "gzip -d $var";
        	$fn = substr($var, 0, -3);
	} else {
        	$fn = "$var";
	}

	open (LOG, $fn) || die "Sorry, cant open. $! \n";
	while (<LOG>)
        	{
		$lines++;
        	chomp;
        	$a = $_;
        	if (($blocktime, $blockip, $email, $stub_id, $nodecount, $os_type, $cpu_type, $version, $core) = split(/,/, $a))
                {

# Do we need to do email verification?
# if( $email =~ m/^[A-Za-z0-9\_-]+@[A-za-z0-9\_-]+.[A-Za-z0-9\_-]+.*/ ) || ( $email =~ m/^[A-Za-z0-9\_-]+.[A-Za-z0-9\_-]+@[A-za-z0-9\_-]+.[A-Za-z0-9\_-]+.* ) {

                if ( $version < 8012 && $os_type == 1 )
                        {
                       	# throw this block out
                       	print REJ "$email, $stub_id, $nodecount, $os_type, $cpu_type, $version\n";
                       	next;
                        }
                if ( $stub_id =~ /^24/ )
                        {
                        print LOG24 "$email,$stub_id,$nodecount,$os_type,$cpu_type,$version\n";
                } else {
                        print LOG25 "$email,$stub_id,$nodecount,$os_type,$cpu_type,$version\n";
                        }
                }
        }
system "bzip2 $fn";
}
close(REJ);
close(LOG24);
close(LOG25);

print "$lines lines processed... ";
$timedone = time();
$tasktime = ($timedone - $timenow);
print "$tasktime seconds to complete filtering of $numargs files.\n";

print "Zipping rejects...\n";
system "bzip2 $reject";

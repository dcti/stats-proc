#!/usr/bin/perl
# 11/28/2002 - Joel Von Holdt for distributed.net
# $Id: filter.pl,v 1.10 2003/02/16 22:47:50 nerf Exp $

use strict;
my ( $var, $fn, $fn24, $fn25, $reject, $numargs, $i );
my ( $tasktime, $timenow, $timedone, $lines, $blocktime, $blockip, $email, $stub_id, $nodecount, $os_type, $cpu_type, $version, $core );

$timenow = time();

$fn24 = "ogr24.filtered";
$fn25 = "ogr25.filtered";
$reject = "rejects.filtered";


{

	while (<STDIN>)
        	{
		$lines++;
        	chomp;
        	$a = $_;
        	if (($blocktime, $blockip, $email, $stub_id, $nodecount, $os_type, $cpu_type, $version, $core) = split(/,/, $a))
                {

# Do we need to do email verification?
# if( $email =~ m/^[A-Za-z0-9\_-]+@[A-za-z0-9\_-]+.[A-Za-z0-9\_-]+.*/ ) || ( $email =~ m/^[A-Za-z0-9\_-]+.[A-Za-z0-9\_-]+@[A-za-z0-9\_-]+.[A-Za-z0-9\_-]+.* ) 

                if ( $version <= 8012 && $os_type == 1 )
                        {
                       	# throw this block out
                       	print STDERR "$email,$stub_id,$nodecount,$os_type,$cpu_type,$version\n";
                       	next;
                        }
                if ( $stub_id =~ /^24/ )
                        {
                        print STDOUT "$email,$stub_id,$nodecount,$os_type,$cpu_type,$version\n";
                } elsif ( $stub_id =~ /^25/ ) {
                        print STDOUT "$email,$stub_id,$nodecount,$os_type,$cpu_type,$version\n";
		} else {
			# throw this block out too.
                       	print STDERR "$email,$stub_id,$nodecount,$os_type,$cpu_type,$version\n";
                       	next;
			}
                }
        }
}

$timedone = time();
$tasktime = ($timedone - $timenow);

#print "Zipping rejects...\n";
#system "bzip2 $reject";

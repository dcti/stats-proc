#!/usr/bin/perl -Tw
#
# $Id: logmod_rc5.pl,v 1.2 2000/06/20 18:23:30 nugget Exp $
#
#
# rc5 logfile sample:
# 06/20/00 01:00:00,10.0.0.1,foo@bar.com,AD2AE1B6C0000000,1,1,1,8004                                                                              
#
# (timestamp, ip, email, block id, block size, os, cpu, version)
#

use strict;

while(<>) {
  my $buf = $_;
  chomp $buf;

  # Precision on smalldatetime is 1 minute.  This doesn't prevent us from
  # bcp'ing the full timestamps into a smalldatetime field, though.  The
  # bcp handles it just fine, and it converts the hh:mm:ss timestamp into
  # hh:mm without difficulty.  However, it rounds to the nearest minute
  # making all blocks done between 23:59:31 and 23:59:59 erroneously
  # rounded up to the next day.  Stripping off the timestamp sidesteps
  # this issue.
  $buf =~ s/(\d\d)\/(\d\d)\/(\d\d) \d\d:\d\d:\d\d/$3$1$2/;

  # Silly two-digit years
  if( int substr($buf,0,2) < 97 ) {
    $buf = "20$buf";
  } else {
    $buf = "19$buf";
  }

  # Split the comma-delimited line into component fields
  my ($timestamp, $ip, $email, $project, $size, $os, $cpu, $version) = split(/,/, $buf);

  # We need to replace the block id with the stats project id.
  # I think hard-coding is our best bet here, which means we need
  # to update this script on each new rc5 project.
  $project = 5; # This is the rc5-64 project id from the Projects table.

  # We remove a few fields prior to import, in order to keep the size of the
  # import table as small as possible.  ip and workunit id are unnecessary
  # for stats, so they are eliminated.

  print "$timestamp,$email,$project,$size,$os,$cpu,$version\n";

}

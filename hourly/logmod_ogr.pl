#!/usr/bin/perl -Tw
#
# $Id: logmod_ogr.pl,v 1.5 2000/07/15 16:47:00 nugget Exp $
#
#
# ogr logfile sample:
#  04/30/00 07:08:26,10.0.0.1,foo@bar.com,24/1-5-15-39-2,7059931784,1,1,8008
#
# (timestamp, ip, email, id, nodes (size), os, cpu, version)
#

use strict;

while(<>) {
  my $buf = $_;
  chomp $buf;

  # This chunk of code attempts to correct commas in email addresses.  This
  # should, of course, never exist.  The proxies and master should fix this
  # but for some reason the cleanup isn't occuring on ogr logs.  Until cow
  # fixes the problem, this code will catch most instances of it.
  while( $buf =~ /^([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*)/ ) {
    $buf = "$1,$2,$3.$4,$5,$6,$7,$8,$9";
  }

  # Strip the workunit id information, leaving only the project id.
  $buf =~ s/\/\d+-[^,]+//;

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

  # We remove a few fields prior to import, in order to keep the size of the
  # import table as small as possible.  ip and workunit id are unnecessary
  # for stats, so they are eliminated.

  print "$timestamp,$email,$project,$size,$os,$cpu,$version\n";

}

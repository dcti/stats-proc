#!/usr/bin/perl -Tw
#
# $Id: logmod_ogr.pl,v 1.3 2000/06/20 16:46:02 nugget Exp $
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

  # Strip the workunit id information, leaving only the project id.
  $buf =~ s/\/\d+-[^,]+//;

  # Precision on smalldatetime is 1 minute.  This doesn't prevent us from
  # bcp'ing the full timestamps into a smalldatetime field, though.  The
  # bcp handles it just fine, and it converts the hh:mm:ss timestamp into
  # hh:mm without difficulty.  However, it rounds to the nearest minute
  # making all blocks done between 23:59:31 and 23:59:59 erroneously
  # rounded up to the next day.  Stripping off the timestamp sidesteps
  # this issue.
  $buf =~ s/ \d\d:\d\d:\d\d//;

  # Split the comma-delimited line into component fields
  my ($timestamp, $ip, $email, $project, $size, $os, $cpu, $version) = split(/,/, $buf);

  # We remove a few fields prior to import, in order to keep the size of the
  # import table as small as possible.  ip and workunit id are unnecessary
  # for stats, so they are eliminated.

  print "$timestamp,$email,$project,$size,$os,$cpu,$version\n";

}

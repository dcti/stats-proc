#!/usr/bin/perl -Tw
#
# $Id: logmod_rc5.pl,v 1.3 2002/01/07 22:43:51 decibel Exp $
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

  # This chunk of code attempts to correct commas in email addresses.  This
  # should, of course, never exist.  The proxies and master should fix this
  # but for some reason the cleanup isn't occuring on ogr logs.  Until cow
  # fixes the problem, this code will catch most instances of it.

  # I know it's dumb to use a regexp to split stuff out, but it seems that after going as far
  # as we need to to fix the 'commas in emails' issue, we might as well just work from what we've
  # got.

  # Find BOL then 2 instances of any text except ',', then any text, then
  # ( a ',' then any text except a ',' then 4 instances of a ',' followed by digits )
  # then EOL
  my ($head, $email, $blockid, $tail);
  if (not ($head, $email, $blockid, $tail) = ($buf =~ /^((?:[^,]+,){2})(.*),([^,]*),((?:\d+)(?:,\d+){3})$/)) {
    print STDERR "BADLOG: $buf\n";
    #print ERR "$buf\n";
    next;
  }
  
  # Do that email comma correcting
  $email =~ s/,/./g;

  # Precision on smalldatetime is 1 minute.  This doesn't prevent us from
  # bcp'ing the full timestamps into a smalldatetime field, though.  The
  # bcp handles it just fine, and it converts the hh:mm:ss timestamp into
  # hh:mm without difficulty.  However, it rounds to the nearest minute
  # making all blocks done between 23:59:31 and 23:59:59 erroneously
  # rounded up to the next day.  Stripping off the timestamp sidesteps
  # this issue.
  my $datestamp;
  if ($head =~ m#^(\d+)/(\d+)/(\d+)#) {
    $datestamp = $3 . $1 . $2;
  } else {
    print STDERR "$buf\n";
    next;
  }

  # Silly two-digit years
  if( int substr($datestamp,0,2) < 97 ) {
    $datestamp = "20$datestamp";
  } else {
    $datestamp = "19$datestamp";
  }

  # We need to replace the block id with the stats project id.
  # I think hard-coding is our best bet here, which means we need
  # to update this script on each new rc5 project.
  my $project = 5; # This is the rc5-64 project id from the Projects table.

  # Split out the tail of the line.
  my ($size, $os, $cpu, $version) = split(/,/, $tail);
 
  # We remove a few fields prior to import, in order to keep the size of the
  # import table as small as possible.  ip and workunit id are unnecessary
  # for stats, so they are eliminated.

  print "$datestamp,$email,$project,$size,$os,$cpu,$version\n";
}

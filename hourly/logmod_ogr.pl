#!/usr/bin/perl -Tw -I../global
#
# $Id: logmod_ogr.pl,v 1.10 2001/03/02 23:40:58 statproc Exp $
#
#
# ogr logfile sample:
#  04/30/00 07:08:26,10.0.0.1,foo@bar.com,24/1-5-15-39-2,7059931784,1,1,8008
#
# (timestamp, ip, email, id, nodes (size), os, cpu, version)
#
# File descriptors:
#  4:	Error output for bad log lines
#  5:	Blocks with blockstatus of 2

use strict;

# Open the file descriptors
#open ERR, ">&=4" or die "Unable to open file descriptor 4!";
#open BADCOUNT, ">&=5" or die "Unable to open file descriptor 5!";

while(<>) {
  my $buf = $_;
  chomp $buf;

  # Standard old log entry:
  # 05/02/00 23:37:38,134.53.131.160,gentleps@muohio.edu,24/1-8-2-25-23,17748654728,1,1,8008
  # Standard new log entry:
  # 05/02/00 23:37:38,134.53.131.160,gentleps@muohio.edu,24/1-8-2-25-23,17748654728,1,1,8008,0
  
  # This chunk of code attempts to correct commas in email addresses.  This
  # should, of course, never exist.  The proxies and master should fix this
  # but for some reason the cleanup isn't occuring on ogr logs.  Until cow
  # fixes the problem, this code will catch most instances of it.

  # I know it's dumb to use a regexp to split stuff out, but it seems that after going as far
  # as we need to to fix the 'commas in emails' issue, we might as well just work from what we've
  # got.

  # Find BOL then 2 instances of any text except ',', then any text, then
  # ( a ',' then any text except a ',' then 4 or 5 instances of a ',' followed by digits )
  # then EOL
  my ($head, $email, $blockid, $tail);

  # First see if we can match the new format (there should be a way to handle both in one regexp, but
  # I couldn't get it to work.
  if (not ($head, $email, $blockid, $tail) = ($buf =~ /^((?:[^,]+,){2})(.*),([^,]*),((?:\d+)(?:,\d+){3}(?:,-?\d+))$/)) {
    # If that didn't work try matching the old format.
    if (not ($head, $email, $blockid, $tail) = ($buf =~ /^((?:[^,]+,){2})(.*),([^,]*),((?:\d+)(?:,\d+){3})$/)) {
      print STDERR "BADLOG: $buf\n";
      #print ERR "$buf\n";
      next;
    }
  }
  
  # Do that email comma correcting
  $email =~ s/,/./g;

  # Strip the workunit id information, leaving only the project id.
  my $projectid;
  if (not ($projectid) = ($blockid =~ /^(\d+)/)) {
    print STDERR "BLOCKID NOT FOUND($blockid): $buf\n";
#    print ERR "$buf\n";
    next;
  }
if ($projectid == 26) {
	$projectid=25;
}

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
#    print ERR "$buf\n";
    next;
  }

  # Silly two-digit years
  if( int substr($datestamp,0,2) < 97 ) {
    $datestamp = "20$datestamp";
  } else {
    $datestamp = "19$datestamp";
  }

  # Split out the tail of the line.
  my ($size, $os, $cpu, $version, $status) = split(/,/, $tail);
  if (not $status) {
	$status = 0;
  }

  if ($status == -1 || $status == 1) {
    print STDERR "$buf\n";
    next;
  } elsif ($status == 0 || $status == 2) {
  # We remove a few fields prior to import, in order to keep the size of the
  # import table as small as possible.  ip and workunit id are unnecessary
  # for stats, so they are eliminated.

  print "$datestamp,$email,$projectid,$size,$os,$cpu,$version\n";
  } else {
    print STDERR "$buf\n";
    #print ERR "$buf\n";
  }
}

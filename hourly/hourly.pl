#!/usr/bin/perl -w 
use strict;
$ENV{PATH} = '/usr/local/bin:/usr/bin:/bin:/opt/sybase/bin';
use stats;

my $yyyy = (gmtime(time-3600))[5]+1900;
my $mm = (gmtime(time-3600))[4]+1;
my $dd = (gmtime(time-3600))[3];
my $hh = (gmtime(time-3600))[2];
my $datestr = sprintf("%04s%02s%02s-%02s", $yyyy, $mm, $dd, $hh);

my $workdir = "./workdir/";

my @projectlist = ("ogr",
                   "rc5");
my @sourcelist  = ("LOGS-SOURCE-FQDN:/home/master/logs/",
                   "LOGS-SOURCE-FQDN:/home/master/logs/");
my @prefilter   = ("./logmod_ogr.pl",
                   "");

for (my $i = 0; $i < @projectlist; $i++) {
  my $project = $projectlist[$i];
  my $lastlog = `cat ~/var/lastlog.$project`;
  my $fullfn = "";
  my $logtoload = "29991231-23";
  my @server = split /:/, $sourcelist[$i];
  chomp($lastlog);

  print "Project $i is $project.\nMy last log was $lastlog\n";

  open LS, "ssh $server[0] ls $server[1]$project*|";
  my $linecount = 0;
  my $qualcount = 0;

  while (<LS>) {
    if( $_ =~ /.*\/$project(\d\d\d\d\d\d\d\d-\d\d)/ ) {
      my $lastdate = $1;
      $fullfn = $_;
      chomp $fullfn;
      if($lastdate gt $lastlog) {
        $qualcount++;
        if($lastdate lt $logtoload) {
          $logtoload = $lastdate;
        }
      }
    }
    $linecount++;
  }
  if( $logtoload lt $datestr ) {
    print "Of $linecount logs available, $qualcount need to be loaded.  Next up is $logtoload.\n";
    print "Retrieving $fullfn:\n";
    open SCP, "scp -Bv $server[0]:$fullfn $workdir 2> /dev/stdout |";
    while (<SCP>) {
      if ($_ =~ /Transferred: stdin (\d+), stdout (\d+), stderr (\d+) bytes in (\d+.\d) seconds/) {
        print "Received $2 bytes in $4 seconds\n";
      }
    }
    # system "scp", "$server[0]:$fullfn", $workdir;
  }
}

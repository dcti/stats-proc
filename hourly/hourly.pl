#!/usr/bin/perl -Tw 
use strict;
$ENV{PATH} = '/usr/local/bin:/usr/bin:/bin';
use stats;

my $yyyy = (localtime(time-3600))[5]+1900;
my $mm = (localtime(time-3600))[4]+1;
my $dd = (localtime(time-3600))[3];
my $hh = (localtime(time-3600))[2];
my $datestr = sprintf("%04s%02s%02s-%02s", $yyyy, $mm, $dd, $hh);


my $project = "csc";
my $incoming = $stats::incoming{$project};

my $file = "$incoming/$project$datestr.log.gz";
print "$file\n\n";
stats::log($project,0,"Looking for $file");
if (!-e $file) {
 stats::log($project,1,"Hmmmm.  I would have expected to see the -$hh log by now.");

  # Pull directory listing of the project's incoming directory. SORT DESC!
  opendir INFILE, $incoming;
  my @infiles = grep /^$project/, readdir INFILE;
  closedir INFILE;
  my @insort = sort { $b cmp $a } @infiles;

  for (my $i = 1; $i < 512; $i++) {
    my $yyyy = (localtime(time-(3600*$i)))[5]+1900;
    my $mm =   (localtime(time-(3600*$i)))[4]+1;
    my $dd =   (localtime(time-(3600*$i)))[3];
    my $hh =   (localtime(time-(3600*$i)))[2];
    my $today = sprintf("%04s%02s%02s%02s", $yyyy, $mm, $dd, $hh);

    if ("$insort[0]" =~ m/^$project(\d\d\d\d\d\d\d\d)-(\d\d)/ ) {
      my $lastlog = "$1$2";
      if ("$lastlog" == "$today") {
        if ( $i > 20 ) {
          stats::log($project,139,"Holy fsck!  It's been $i hours since I got a log file!");
        } else {
          if ( $i > 12 ) {
            stats::log($project,3,"It's been $i hours since I got a log file.");
          } else {
            if ( $i > 3 ) {
              stats::log($project,1,"It's been $i hours since I got a log file.");
            }
          }
        }
        $i = 512;
      }
    } 
  } 
} else {
  my $retcode = system "gzip", "-tv",$file;
  if ( $retcode > 0 ) {
    stats::log($project,139,"The -$hh file seems to be corrupt.");
  } else {
    stats::log($project,1,"The -$hh logfile looks fine.");
  }
}

#!/usr/bin/perl -w -I../global
#
# $Id: daily.pl,v 1.7 2000/08/16 17:46:31 nugget Exp $

use strict;
$ENV{PATH} = '/usr/local/bin:/usr/bin:/bin:/opt/sybase/bin';

#$0 =~ /(.*\/)([^\/]+)/;
#my $cwd = $1;
#my $me = $2;
#chdir $cwd;

use statsconf;
use stats;

my $yyyy = (gmtime(time-3600))[5]+1900;
my $mm = (gmtime(time-3600))[4]+1;
my $dd = (gmtime(time-3600))[3];
my $hh = (gmtime(time-3600))[2];
my $datestr = sprintf("%04s%02s%02s-%02s", $yyyy, $mm, $dd, $hh);

my $respawn = 0;

my $workdir = "./workdir/";

if(!$ARGV[0]) {
  stats::log("stats",132,"Some darwin just called hourly.pl without supplying a project code!");
  die;
}
my $project = $ARGV[0];

stats::log($project,1,"Beginning daily processing routines");

my @pridlist = split /:/, $statsconf::prids{$project};
for (my $i = 0; $i < @pridlist; $i++) {
  my $project_id = int $pridlist[$i];

  sqsh("retire.sql $project_id");
  sqsh("dy_appendday.sql $project_id");
  sqsh("em_rank.sql $project_id");
  sqsh("tm_rank.sql $project_id");
  sqsh("dy_dailyblocks.sql $project_id");
  sqsh("audit.sql $project_id");

  sqsh("clearday.sql $project_id");
  system "sudo pcpages_$project $project_id";
  sqsh("backup.sql $project_id");
}

sub sqsh {
  my ($sqlfile) = @_;

  my $bufstorage = "";
  my $sqshsuccess = 0;
  my $starttime = (gmtime);
  open SQL, "sqsh -S$statsconf::sqlserver -U$statsconf::sqllogin -P$statsconf::sqlpasswd -i $sqlfile |";

  if(!<SQL>) {
    stats::log($project,131,"Failed to launch $sqlfile -- aborting.");
    die;
  }
  while (<SQL>) {
    my $ts = sprintf("[%02s:%02s:%02s]",(gmtime)[2],(gmtime)[1],(gmtime)[0]);
    print "$ts $_";
    $bufstorage = "$bufstorage$ts $_";
    if( $_ =~ /^Msg/ ) {
      $sqshsuccess = 1;
    }
    if( $_ =~ /ERROR/ ) {
      $sqshsuccess = 1;
    }
  }
  close SQL;
  if( $sqshsuccess > 0) {
    stats::log($project,131,"$sqlfile puked  -- aborting.  Details are in $workdir\sqsh_errors");
    open SQERR, ">$workdir\sqsh_errors";
    print SQERR "$bufstorage";
    close SQERR;
    die;
  }
}


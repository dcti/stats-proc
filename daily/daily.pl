#!/usr/bin/perl -w -I../global
#
# $Id: daily.pl,v 1.31.2.1 2003/04/27 20:47:04 decibel Exp $

use strict;
$ENV{PATH} = '/usr/local/bin:/usr/bin:/bin:/usr/local/sybase/bin:/opt/sybase/bin';

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
if(! -d $workdir) {
  stats::log("stats",131,"Hey! Someone needs to mkdir $workdir!");
  die;
}
if(!$ARGV[0]) {
  stats::log("stats",131,"Some darwin just called daily.pl without supplying a project code!");
  die;
}
my $project = $ARGV[0];

# This is a big-time kludge to make sure we don't walk on the RC5 run
if (-e '/home/incoming/newlogs-rc5/nologs.lck') {
  stats::log($project,131,'/usr/home/incoming/newlogs-rc5/nologs.lck exists; aborting.');
  die;
}

stats::log($project,5,"Beginning daily processing routines");

if(!$statsconf::prids{$project}) {
  stats::log($project,131,"I've never heard of project class $project!");
  die;
} else {
  my @pridlist = split /:/, $statsconf::prids{$project};
  for (my $i = 0; $i < @pridlist; $i++) {
    my $project_id = int $pridlist[$i];
  
    psql("retire.sql");
    psql("newjoin.sql");
    psql("dy_appendday.sql");
    psql("em_update.sql");
    psql("em_rank.sql");
    psql("tm_update.sql");
    psql("tm_rank.sql");
    psql("platform.sql");
    psql("dy_dailyblocks.sql");
    system "sudo pcpages $project_id";
    psql("audit.sql");

    psql("clearday.sql");
    psql("backup.sql");
  }
  my $newlastday = stats::lastday($project);
  stats::log($project,5,"Daily processing for $newlastday has completed");
}

sub psql {
  my ($sqlfile) = @_;

  my $bufstorage = "";
  my $psqlsuccess = 0;
  my $starttime = (gmtime);
  my $secs_start = int `date "+%s"`;
  if(!open SQL, "psql -d $statsconf::database -f $sqlfile -v ProjectID=$project_id 2>&1 |") {
    stats::log($project,131,"Failed to launch $sqlfile -- aborting.");
    die;
  }

  while (<SQL>) {
    my $ts = sprintf("[%02s:%02s:%02s]",(gmtime)[2],(gmtime)[1],(gmtime)[0]);
    my $buf = $_;
    chomp $buf;
    if ($buf ne "") {
      stats::log($project,0,$buf);
      $bufstorage = "$bufstorage$ts $_";
    }
    if( $_ =~ /^Msg/ ) {
      $psqlsuccess = 1;
    }
    if( $_ =~ /ERROR/ ) {
      $psqlsuccess = 1;
    }
  }

  close SQL;
  if( $psqlsuccess > 0) {
    stats::log($project,147,"$sqlfile puked  -- aborting.  Details are in $workdir\psql_errors");
    open SQERR, ">$workdir\psql_errors" or stats::log($project,139,"Unable to open $workdir\psql_errors for writing!");
    print SQERR "$bufstorage";
    close SQERR;
    die $psqlsuccess;
  }
  my $secs_finish = int `date "+%s"`;
  my $secs_run = $secs_finish - $secs_start;
  stats::log($project,1,"$sqlfile completed successfully ($secs_run seconds)");
}


#!/usr/bin/perl -w -I../global
#
# $Id: daily.pl,v 1.41 2005/05/31 06:39:53 jlawson Exp $

use strict;
$ENV{'PATH'} = '/usr/local/bin:/usr/bin:/bin:/usr/local/sybase/bin:/opt/sybase/bin';

#$0 =~ m/^(.*\/)([^\/]+)$/ or die;
#my $cwd = $1;
#my $me = $2;
#chdir $cwd;

use statsconf;
use stats;

my ($yyyy,$mm,$dd,$hh) = (gmtime(time-3600))[5,4,3,2];
$yyyy += 1900;
$mm += 1;
my $datestr = sprintf("%04s%02s%02s-%02s", $yyyy, $mm, $dd, $hh);

my $respawn = 0;

$statsconf::pcpages_pre = '' if ! defined $statsconf::pcpages_pre;
stats::debug( 1, "CONFIG: pcpages_pre = '$statsconf::pcpages_pre'");

($ENV{'HOME'} . '/workdir/daily/') =~ m/^(/[A-Za-z0-9_\-\/]+)$/ 
    or die "unsafe HOME directory";
my $workdir = $1;       # ensures untaintedness

($ENV{'HOME'} . '/stats-proc/misc/pcpages') =~ m/^(/[A-Za-z0-9_\-\/]+)$/ 
    or die "unsafe HOME directory";
my $pcpages = $1;       # ensures untaintedness

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
  
    psql("retire.sql", $project_id);
    psql("newjoin.sql", $project_id);
    psql("dy_appendday.sql", $project_id);
    psql("em_update.sql", $project_id);
    psql("em_rank.sql", $project_id);
    psql("tm_update.sql", $project_id);
    psql("tm_rank.sql", $project_id);
    psql("platform.sql", $project_id);
    psql("dy_dailyblocks.sql", $project_id);
    if (lc($statsconf::pcpages_pre) ne 'no') {
        system "$statsconf::pcpages_pre $pcpages $project_id";
    }
    psql("audit.sql", $project_id);

    psql("clearday.sql", $project_id);
    psql("backup.sql", $project_id);
  }
  my $newlastday = stats::lastday($project);
  stats::log($project,5,"Daily processing for $newlastday has completed");
}

sub psql {
  my ($sqlfile, $project_id) = @_;

  my $bufstorage = "";
  my $psqlsuccess = 0;
  my $starttime = (gmtime);
  my $secs_start = int `date "+%s"`;
  if(!open SQL, "psql -d $statsconf::database -f $sqlfile -v ProjectID=$project_id 2>&1 |") {
    stats::log($project,131,"Failed to launch $sqlfile -- aborting.");
    die;
  }

  while (<SQL>) {
    my $ts = sprintf("[%02s:%02s:%02s]",(gmtime)[2,1,0]);
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
    if( $_ =~ /FATAL/ ) {
      $psqlsuccess = 1;
    }
  }

  close SQL;
  if( $psqlsuccess > 0) {
    stats::log($project,128+16+8+2+1,"$sqlfile puked  -- aborting.  Details are in $workdir/psql_errors");
    open SQERR, ">$workdir/psql_errors" or stats::log($project,139,"Unable to open $workdir/psql_errors for writing!");
    print SQERR "$bufstorage";
    close SQERR;
    die $psqlsuccess;
  }
  my $secs_finish = int `date "+%s"`;
  my $secs_run = $secs_finish - $secs_start;
  stats::log($project,1,"$sqlfile for project $project_id completed successfully ($secs_run seconds)");
}


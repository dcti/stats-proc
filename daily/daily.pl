#!/usr/bin/perl -Tw
#
# $Id: daily.pl,v 1.2 2000/02/21 03:47:06 bwilson Exp $
#
die;
use strict
$ENV{PATH} = '/usr/local/sybase/bin:/usr/local/bin:/usr/bin:/bin';
use stats;

my $sqllogin = "-Ustatproc";
my $sqlpasswd = "-PPASSWORD";
my $sqlserver = "-STALLY";

my $project = "OGR";
my $incoming = $stats::incoming{$project};
my $projectdir = $stats::projectdir{$project};

my $yyyy = (localtime)[5]+1900;
my $mm = (localtime)[4]+1;
my $dd = (localtime)[3];
my $today = sprintf("%04s%02s%02s", $yyyy, $mm, $dd);

stats::log($project,133,"daily-$project stats run has started");

my $maxdate = `sqsh -h -i dy_maxdate.sql $project`;
stats::log($project,1,"Last entry in stats database is for $maxdate");

# Pull directory listing of the project's incoming directory.
opendir INFILE, $incoming;
my @infiles = grep /^$project/, readdir INFILE;
closedir INFILE;
my @insort = sort @infiles;

# Grab date component out of earliest log's filename for comparison.
if ("$insort[0]" =~ m/^$project(\d\d\d\d\d\d\d\d)/ ) {
  my $earlyday = $1;
  stats::log($project,1,"Earliest logfile is $earlyday.");
  # Test to see if there are logs we need to process.
#  if ( $earlyday >= $today ) {
  if ( undef ) {
    # There are no logs to be processed

    stats::log($project,1,"There does not appear to be any work for me to do.");
    if ($maxdate >= $today-1) {
      stats::log($project,1,"Since it looks like the stats database is current anyway, I don't see this as any big deal.  Wake me up when you have something for me to do.");
    } else {
      stats::log($project,131,"I think there's a problem.  I need work to do.");
    }
  } else {
    # OK, There are logs to be processed here.
    # First thing we'll want to do is make sure there's at least 24 files.

    # Let's re-read the directory, just for $earlyday
    opendir INFILE, $incoming;
    my @infiles = grep/^$project$earlyday/, readdir INFILE;
    closedir INFILE;
    my @insort = sort @infiles;
    my $innum = scalar(@infiles);

    stats::log($project,1,"There are $innum logfiles to process for $earlyday.");
    if ($innum < 24) {
      stats::log($project,1,"Hrm, that sounds low to me.  I think I'll wait for someone to tell me what to do.");
      #######
      # OK, So this code needs to be written.
      #######
    }

    stats::log($project,1,"Now I will test all these logs, to make sure they're healthy.");
    my $badfiles = 0;
    for ($i = 0; $i < $innum; $i++) {
      my $fullpath = "$incoming/$insort[$i]";
      $retcode = system "gzip","-tv",$fullpath;
      if ( $retcode > 0 ) {
        $badfiles = $badfiles + 1;
        stats::log($project,1,"The file $insort[$i] is not healthy!");
      }
    }
    if ($badfiles > 0 ) {
      stats::log($project,139,"I can't continue until someone straghtens out these logfiles!  Aborting.");
      die;
    }
    stats::log($project,1,"All the log files look fine to me.");

    # We don't want to import these logs if this day already exists in the database, right?
    my $dayrows = `sqsh -h -i dy_checkday.sql $project $earlyday`;
    if ($dayrows > 0) {
      stats::log($project,131,"Um. Something doesn't look right.  I'm about to load the $earlyday logs, but there's already data for that day in the master table.  Someone tell me what to do.");
      stats::log($project,8,"Possible duplicate day load.  Aborting.");
#      die;
    }

    for ($i = 0; $i < $innum; $i++) {
      my $fullpath = "$incoming/$insort[$i]";
      $retcode = system "cp",$fullpath,"./stalelogs";
      $retcode = system "touch $incoming/nologs.lck";
      $retcode = system "chmod 666 $incoming/nologs.lck";
      $retcode = system "mv",$fullpath,"./workdir";
      if ( $retcode > 0 ) {
        stats::log($project,139,"Error moving logs to workdir!");
        die;
      }
    }

    $retcode = system "sqsh -i cleardaytable.sql $project";
    stats::log($project,1,"Cleared day table");

    $retcode = system "sudo cleartran";
    stats::log($project,1,"transaction logs dumped");

    my $recsday = 0;

    for ($i = 0; $i < $innum; $i++) {
      my $fullpath = "./workdir/$insort[$i]";
      my $recsval = 0;
      stats::log($project,0,"Beginning decompression of $fullpath");
      $retcode = system "gzip", "-d", $fullpath;
      if ( $retcode > 0 ) {
        stats::log($project,139,"Error decompressing $fullpath! Aborting.");
        die;
      }
      my $unzipfn = "";
      if ("$fullpath" =~ m/(.*)\.gz/) {
        $unzipfn = $1;
      }
      $retcode = system "sqsh -i clearimport.sql $project";
      # bcp cimport in $1 -ebcp_errors -STALLY -Ustatproc -PPASSWORD -c -t,
      $retcode = system "bcp", "$project" . "_import", "in", $unzipfn, "-ebcp_errors", $sqlserver, $sqllogin, $sqlpasswd, "-c", "-t,";
      if ( $retcode > 0 ) {
        stats::log($project,139,"BCP Failed!");
        die;
      } else {
        my $recs = `sqsh -h -i dy_importcount.sql $project`;
        $recsval = 0+$recs;
        $recsday = $recsday + $recsval;
        stats::log($project,0,"BCP of $unzipfn complete, $recsval records imported. [$retcode]");
      }
      unlink $unzipfn;
      $retcode = system "sqsh -i dy_integrate.sql $project";
      stats::log($project,1,"BCP/Import of $unzipfn complete.  $recsval rows imported. [$retcode]");
    }
    stats::log($project,1,"All logfiles have been added to the daytables.  $recsday rows total.");

    $retcode = system "sqsh -i dy_fixemails.sql $project";
    stats::log($project,1,"Cleaned all the bad emails");
    $retcode = system "sqsh -i dy_newemails.sql $project";
    stats::log($project,1,"Added new emails to STATS_participant");
    $retcode = system "sqsh -i dy_appendday.sql $project";
    stats::log($project,1,"Appened day's activity to master table");

    $retcode = system "sqsh -i dp_newjoin.sql $project";
    stats::log($project,1,"Applied Retroactive Team Joins");

    $retcode = system "sqsh -i dp_em_rank.sql $project";
    stats::log($project,5,"Emails Ranking complete (Overall)");
    $retcode = system "sqsh -i dp_em_yrank.sql $project";
    stats::log($project,5,"Emails Ranking complete (Yesterday)");

    $retcode = system "sqsh -i dy_members.sql $project";
    stats::log($project,1,"CACHE_tm_MEMBERS table built");

    $retcode = system "sqsh -i dp_tm_rank.sql $project";
    stats::log($project,5,"Teams Ranking complete (Overall)");
    $retcode = system "sqsh -i dp_tm_yrank.sql $project";
    stats::log($project,5,"Teams Ranking complete (Yesterday)");

    $retcode = system "sqsh -i dy_dailyblocks.sql $project";
    stats::log($project,1,"CACHE_dailyblocks table built");

    $retcode = system "sudo $project" . "pages";
    stats::log($project,1,"pc_web pages generated");

    ######
    # OK, Here we should test to see if another day is stacked.
    ######

    # Pull directory listing of the project's incoming directory.
    opendir INFILE, $incoming;
    @infiles = grep /^$project/, readdir INFILE;
    closedir INFILE;
    @insort = sort @infiles;

    # See if there's logs to process
    if (scalar(@infiles)>0) {

      # Grab date component out of earliest log's filename for comparison.
      if ("$insort[0]" =~ m/^$project(\d\d\d\d\d\d\d\d)/ ) {
        my $earlyday = $1;
        # Test to see if there are logs we need to process.
        if ( $earlyday < $today ) {
          stats::log($project,1,"I see logs for $earlyday, I think I'll get caught up before re-ranking.");
          exec "./daily.pl";
        }
      }
    }

    system "rm $incoming/nologs.lck";

  }
} else {
  # For some reason, the regex match failed to identify the earliest file
  # as a logfile.

  stats::log($project,139,"I cannot determine the earliest logfile's date.  Aborting.");
  die;
}
stats::log($project,133,"daily-$project stats run has ended");

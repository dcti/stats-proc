#!/usr/bin/perl -Tw
use strict
$ENV{PATH} = '/usr/local/sybase/bin:/usr/local/bin:/usr/bin:/bin';
use stats;

my $sqllogin = "-Ustatproc";
my $sqlpasswd = "-PSlfk39do";
my $sqlserver = "-STALLY";

my $project = "rc5";
my $incoming = $stats::incoming{$project};
my $projectdir = $stats::projectdir{$project};

my $yyyy = (localtime)[5]+1900;
my $mm = (localtime)[4]+1;
my $dd = (localtime)[3];
my $today = sprintf("%04s%02s%02s", $yyyy, $mm, $dd);

stats::log($project,0,"daily-$project started");


# Pull directory listing of the project's incoming directory.
opendir INFILE, $incoming;
my @infiles = grep /^rc5/, readdir INFILE;
closedir INFILE;
my @insort = sort @infiles;

# Grab date component out of earliest log's filename for comparison.
if ("$insort[0]" =~ m/^rc5(\d\d\d\d\d\d\d\d)/ ) {
  my $earlyday = $1;
  stats::log($project,0,"Earliest logfile is $earlyday.");

  # Test to see if there are logs we need to process.
  if ( $earlyday >= $today ) {
    # There are no logs to be processed

    stats::log($project,0,"There does not appear to be any work for me to do.");

    ########
    # I'll want to put code here to test if today == max(date) in master
    # That will control how loudly I scream.
    ########
  } else {
    # OK, There are logs to be processed here.
    # First thing we'll want to do is make sure there's at least 24 files.
    # Let's re-read the directory, just for $earlyday

    opendir INFILE, $incoming;
    my @infiles = grep/$earlyday/, readdir INFILE;
    closedir INFILE;
    my @insort = sort @infiles;
    
    my $innum = scalar(@infiles);

    stats::log($project,0,"There are $innum logfiles to process for $earlyday.");
    if ($innum < 24) {
      stats::log($project,0,"Hrm, that sounds low to me.  I think I'll wait for someone to tell me what to do.");
      
      #######
      # OK, So this code needs to be written.
      #######
    }

    stats::log($project,0,"Now I will test all these logs, to make sure they're healthy.");
    my $badfiles = 0;
    for ($i = 0; $i < $innum; $i++) {
      my $fullpath = "$incoming/$insort[$i]";
      $retcode = system "gzip","-tv",$fullpath;
      if ( $retcode > 0 ) {
        $badfiles = $badfiles + 1;
        stats::log($project,0,"The file $insort[$i] is not healthy!");
      } 
    }
    if ($badfiles > 0 ) {
      stats::log($project,0,"I can't continue until someone straghtens out these logfiles!  Aborting.");
      die;
    }
    stats::log($project,0,"All the log files look fine to me.");
   
    for ($i = 0; $i < $innum; $i++) {
      my $fullpath = "$incoming/$insort[$i]";
      $retcode = system "cp",$fullpath,"./stalelogs";
      $retcode = system "mv",$fullpath,"./workdir";
      if ( $retcode > 0 ) {
        stats::log($project,0,"Error moving logs to workdir!");
        die;
      }
    }

    $retcode = system "sqsh -i cleardaytable.sql";
    stats::log($project,0,"Cleared day table");

    for ($i = 0; $i < $innum; $i++) {
      my $fullpath = "./workdir/$insort[$i]";
      stats::log($project,0,"Beginning decompression of $fullpath");
      $retcode = system "gzip", "-d", $fullpath;
      if ( $retcode > 0 ) {
        stats::log($project,0,"Error decompressing $fullpath! Aborting.");
        die;
      }
      print "\n $fullpath := ";
      my $unzipfn = "";
      if ("$fullpath" =~ m/(.*)\.gz/) {
        $unzipfn = $1;
        print "$unzipfn";
      }
      print "\n";
      $retcode = system "sqsh -i clearimport.sql";
      $retcode = system "./bcpwrapper", $unzipfn;
      if ( $retcode > 0 ) {
        stats::log($project,0,"BCP Failed!");
        die;
      } else {
        stats::log($project,0,"BCP of $unzipfn complete [$retcode]");
      }
      unlink $unzipfn;
      $retcode = system "sqsh -i dy_integrate.sql";
      stats::log($project,0,"Logfile appended to daytables");
    }
    stats::log($project,0,"All logfiles have been added to the daytables");
  }
} else {
  # For some reason, the regex match failed to identify the earliest file
  # as a logfile.

  stats::log($project,0,"I cannot determine the earliest logfile's date.  Aborting.");
  die;
}
stats::log($project,0,"daily-$project ended");

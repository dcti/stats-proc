#!/usr/bin/perl -I../global
#!/usr/bin/perl -Tw -I../global
#
# $Id: OGRhourly.pl,v 1.1 2003/01/18 07:47:11 nerf Exp $
#
# This is a straight ripoff of ../hourly/hourly.pl
# Once we move stats to pgsql, thetwo hourly processing files should be merged
# This is especially true, as there is no need to pull the logs twice (or copy
# them into the db twice).

# For now, I'm just cronning this activity.  It's possible that we'll find we want to build our
# own scheduler, however.
#
# 4 * * * * cd /usr/home/statproc/stats-proc/OGRhourly && ./OGRhourly.pl > /usr/home/statproc/log/lastrun.OGRhourly  2> /usr/home/statproc/log/lastrun.OGRhourly.err
#
# The cd is because my clever chdir code below (commented-out) isn't sufficient.
# Our -I../global for "use stats" and "use statsconf" relies on being started from
# the right directory.  This is inelegant and needs to be cleaned up.
#
# the 2> redirect of stderr seems to be necessary, although I'm not certain why.
# Without it, the script is unable to spawn bcp or sqsh claiming the inability
# to access /dev/stderr.  *shrug*

use strict;
$ENV{PATH} = '/usr/local/bin:/usr/bin:/bin';

#$0 =~ /(.*\/)([^\/]+)/;
#my $cwd = $1;
#my $me = $2;
#chdir $cwd;

use statsconf;
use stats;

my $respawn = 0;

my $workdir = "./workdir/";

my $project = "ogr-verification";
  
# Check to see if we're locked, but don't set it until it's time to actually do some work
#
# NOTE:
# This means that anything that actually modifies data should not happen until after we set
# the lock.
if ($_ = stats::semcheck('OGRhourly')) {
  stats::log($project,129,"Cannot obtain lock for OGRhourly.pl!  [$_] still running!");
  #next RUNPROJECTS;
  die;
}
my $sourcelist = $statsconf::logsource{$project};
my $prefilter = $statsconf::prefilter{$project};
my $outbuf = "";
my @server = split /:/, $sourcelist;

# Check to see if workdir is empty
opendir WD, "$workdir" or die;
my @wdcontents = grep !/^(CVS|\.\.?)$/, readdir WD;
closedir WD;

if(@wdcontents > 0) {
  stats::log($project,131,"Workdir is not empty!  I refuse to proceed with OGRhourly processing.");
  die;
}

my ($logtoload,$logext,$qualcount) = findlog($project);

if( $qualcount > 0 ) {
  my ($yyyymmdd, $hh) = split /-/, $logtoload;

  my $lastday = stats::lastday($project);
  chomp $lastday;

  if ($lastday eq "") {
    stats::log($project,131,"Warning: It appears that there has never been a daily run for this project.");
  } else {
    my $lasttime = timegm(0,0,0,(substr $lastday, 6, 2),((substr $lastday, 4, 2)-1),(substr $lastday, 0, 4));
    my $logtime = timegm(0,0,0,(substr $yyyymmdd, 6, 2),((substr $yyyymmdd, 4, 2)-1),(substr $yyyymmdd, 0, 4));
  
    if ( $lasttime != ($logtime - 86400)) {
      stats::log($project,139,"Aborting: I'm supposed to load a log from $yyyymmdd, but my last daily processing run was for $lastday!");
      die;
    }
  }

  if($qualcount > 1) {
     # We should respawn at the end to catch up...
     $respawn = 1;
  }

  my $fullfn = "$server[1]$project$logtoload$logext";
  my $basefn = "$project$logtoload$logext";

  # Go ahead and set the lock now
  if($_ = stats::semflag('OGRhourly',"OGRhourly.pl") ne "OK") {
    stats::log($project,129,"Cannot obtain lock for OGRhourly.pl!  [$_] still running!");
    die;
  }

  $outbuf = "";
  open SCP, "scp -Bv $server[0]:$fullfn $workdir 2> /dev/stdout |";
  while (<SCP>) {
    if ($_ =~ /Transferred: stdin (\d+), stdout (\d+), stderr (\d+) bytes in (\d+.\d) seconds/) {
      my $rate = rate_calc($2,$4);
      my $size = num_format($2);
      my $time = num_format($4);
      $outbuf = "$basefn received: $size bytes in $time seconds ($rate)";
    }
  }
  close SCP;
  if ($outbuf eq "") {
    stats::log($project,1,"$basefn received");
  } else {
    stats::log($project,1,$outbuf);
  }

  my $rawfn = "";
  if ( $logext =~ /.gz$/ ) {
	open GZIP, "gzip -dv $workdir$basefn 2> /dev/stdout |";
	while (<GZIP>) {
	  if ($_ =~ /$basefn:[ \s]+(\d+.\d)% -- replaced with (.*)$/) {
	    $rawfn = $2;
	    $rawfn =~ s/$workdir//;
	    stats::log($project,1,"$basefn successfully decompressed ($1% compression)");
	  }
	}
  } elsif ( $logext =~ /.bz2$/ ) {
	my $orgsize=(stat "$workdir$basefn")[7];
	system("bzip2 -d $workdir$basefn");
	if ($? == 0) {
	    $rawfn = $basefn;
	    $rawfn =~ s/.bz2//i;
	    my $newsize=(stat "$workdir$project$rawfn")[7];
	    stats::log($project,1,"$basefn successfully decompressed (" . int($newsize/$orgsize*100) . "% compression)");
	}
  }
  if( $rawfn eq "" ) {
    stats::log($project,130,"$basefn failed decompression!");
  } else {
    {
	`cat $workdir$rawfn | $prefilter > $workdir$finalfn 2>> ./filter_$project.err`;
	if ($? == 0) {
	    stats::log($project,1,"$rawfn successfully filtered through $prefilter.");
	} else {
	    stats::log($project,131,"unable to filter $rawfn through $prefilter!");
	    die;
	}
    }

    open COPYFROM, "psql ogr -c\"COPY logdata FROM \'$workdir$finalfn\' USING DELIMITERS ',';\" |";
    if(!<COPYFROM>) {
      stats::log($project,131,"Error launching COPY FROM, aborting OGRhourly run.");
      die;
    }


      # It's always good to clean up after ourselves for the next run.
      unlink "$workdir$finalfn", "$workdir$rawfn";

      stats::lastlog($project,$logtoload);

      if($hh == 23) {
        if(stats::lastday($project) < $yyyymmdd) {
          # Note -- CWD is not clean after calling spawn_daily.  Always use absolute
          # Paths after calling this.  (yeah, I know that's ugly)
          spawn_daily($project);
        }
      }
    }
    close GZIP;
  }
  if(stats::semflag('OGRhourly') ne "OK") {
    stats::log($project,139,"Error clearing OGRhourly.pl lock");
    die;
  }

if ($respawn > 0) {
  exec "./OGRhourly.pl";
}

sub spawn_daily {

  my ($f_project) = @_;

  stats::log($f_project,1,"Spawning movedata.sql");
  if ( ($_ = system("psql ogr -f ./movedata.sql")) != 0 ) {
    stats::log($f_project,1,"movedata.sql generated an error code of $_, \"$!\"!");
    die;
  }
  stats::log($f_project,1,"movedata.sql complete for $f_project");

}

sub findlog {
  # Get list of logs that are on the master
  # Accepts:
  #    $project
  #
  # Returns
  #    log to work with, or empty string if none.
  #    trailing end of logfile (everything after the timestamp)
  #    number of logs left to process

  scalar(@_) == 1 or die "Improper number of arguments (" . scalar(@_) . ") passed to findlog";
  my ($project) = @_;

  my @server = split /:/, $statsconf::logsource{$project};

  use Time::Local;
  
  my $yyyy = (gmtime(time-3600))[5]+1900;
  my $mm = (gmtime(time-3600))[4]+1;
  my $dd = (gmtime(time-3600))[3];
  my $hh = (gmtime(time-3600))[2];
  my $datestr = sprintf("%04s%02s%02s-%02s", $yyyy, $mm, $dd, $hh);
  my $logtoload = "29991231-23";
  my $logext;
  my $lastlog = stats::lastlog($project,"get");
  chomp($lastlog);

  stats::log($project,1,"Looking for new logs, last log processed was $lastlog");

  # fscking linux.  There's a damn good reason why bash isn't a
  # suitable replacement for sh and here's an example.
  if( !open LS, "tcsh -c 'ssh $server[0] \"ls -l $server[1] | grep $project\"'|" ) {
    stats::log($project,131,"Unable to contact log source!");
    return "",0;
  } 

  my $linecount = 0;
  my $qualcount = 0;

  while (<LS>) {
    if( $_ =~ /-(...)(...)(...).*$project(\d\d\d\d\d\d\d\d-\d\d)(.*)/ ) {
      my $lastdate = $4;
      my $lastext = $5;

      # Found a log. Is it newer than the last log we processed?
      if($lastdate gt $lastlog) {
        $qualcount++;
        if($lastdate gt $datestr) {
          # This log is the "active" log, we don't want to count it in our summary.
          $qualcount--;
        }
	
	# We start with $logtoload set impossibly high (new). If we find a log that's older than $logtoload,
	# and it's older than our current time - 1 hour ($datestr), mark it as the log to load. Once we've
	# processed all the available logs, $logtoload will have the lowest possible log we can load. Note
	# that some unexpected things will happen if we don't get the log list sorted in date order according
	# to the log filename
        if(($lastdate lt $logtoload) and ($lastdate le $datestr)) {
          if(! ($2 =~ /r/) ) {
            stats::log($project,131,"I need to load log $lastdate, but I cannot because the master created it with the wrong permissions!");
            die;
          }
          print $_;
          if(! ($_ =~ /(gz|bz2)$/) ) {
            stats::log($project,131,"The master failed to compress the $lastdate logfile.  Skipping to next project.");
	    return "",0;
          }
          $logtoload = $lastdate;
	  $logext = $lastext;
        }
      }
    }
    $linecount++;
  }

  if($linecount == 0) {
    stats::log($project,131,"No log files found!");
    return "","",0;
  }

  if($qualcount == 1) {
    stats::log($project,1,"There are $linecount logs on the master, $qualcount is new to me.  Might as well load it while I'm thinking about it.");
  } elsif($qualcount > 1) {
    stats::log($project,1,"There are $linecount logs on the master, $qualcount are new to me.  I think I'll start with $logtoload.");
  }

  return $logtoload,$logext,$qualcount;
}

sub num_format {
  my ($f_num) = @_;
  my $f_outstr = "";
  my $f_counter = 0;
  my $f_dotspot = 0;
  if($f_num =~ m/\./g) {
    $f_dotspot = (pos $f_num)-1;
  } else {
    $f_dotspot = 999;
  }
  for(my $i=length($f_num)-1; $i>=0; $i--) {
     my $f_char = substr($f_num,$i,1);
     if( $f_counter == 3 ) {
       $f_outstr = "$f_char,$f_outstr";
       $f_counter = 0;
     } else {
       $f_outstr = "$f_char$f_outstr";
     }
     if($i < $f_dotspot) {
       $f_counter++;
     }
  }
  return $f_outstr;
}

sub rate_calc {
  my ($bytes,$secs) = @_;
  my @units = ('B/s','KB/s','MB/s');
  my $work = $bytes/$secs;

  my $i = 0;
  my $unit = $units[0];
  while($work>1000) {
    $work = $work/1000;
    $i++;
    $unit = $units[$i];
  }

  $work = sprintf "%.1f", $work;

  my $f_num = num_format($work);
  my $f_outstr = "$f_num $unit";

  return $f_outstr;
}

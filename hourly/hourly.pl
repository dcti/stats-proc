#!/usr/bin/perl -Tw -I../global
#
# $Id: hourly.pl,v 1.135 2006/02/27 16:17:49 nerf Exp $
#
# For now, I'm just cronning this activity.  It's possible that we'll find we want to build our
# own scheduler, however.
#
# 4 * * * * cd /usr/home/statproc/stats-proc/hourly && ./hourly.pl > /usr/home/statproc/log/lastrun.hourly  2> /usr/home/statproc/log/lastrun.hourly.err
#
# The cd is because my clever chdir code below (commented-out) isn't sufficient.
# Our -I../global for "use stats" and "use statsconf" relies on being started from
# the right directory.  This is inelegant and needs to be cleaned up.
#
# the 2> redirect of stderr seems to be necessary, although I'm not certain why.
# Without it, the script is unable to spawn bcp or psql claiming the inability
# to access /dev/stderr.  *shrug*

use strict;
$ENV{PATH} = '/usr/local/bin:/usr/bin:/bin';

#$0 =~ /(.*\/)([^\/]+)/;
#my $cwd = $1;
#my $me = $2;
#chdir $cwd;

use statsconf;
use stats;

#
# spawn_daily
#
sub spawn_daily ($) {
  my ($f_project) = @_;

  chdir "../daily/";

  stats::log($f_project,1,"Spawning daily.pl for $f_project");
  if ( ($_ = system("./daily.pl $f_project")) != 0 ) {
    stats::log($f_project,1,"daily.pl generated an error code of $_, \"$!\"!");
    die;
  }
  stats::log($f_project,1,"daily.pl complete for $f_project");
  chdir "../hourly";

}

#
# findlog
#
sub findlog ($$) {
  my ($project, $logprefix) = @_;
  # Get list of logs that are on the master
  # Accepts:
  #   $project
  #   $logprefix
  #
  # Returns
  #    log to work with, or empty string if none.
  #    trailing end of logfile (everything after the timestamp)
  #    number of logs left to process

  my @server = split /:/, $statsconf::logsource{$project};

  use Time::Local;
  
  my $logtoload = "29991231-23";
  my $logext = '';
  my $lastlog = stats::lastlog($project);

  if (defined($lastlog) ) {
    stats::log($project,1,"Looking for new logs, last log processed was $lastlog");
  } else {
    stats::log($project,128+2+1,"Warning: It appears that no logs have ever been loaded for this project.");
    $lastlog='';
  }

  if (defined($server[1])) {
    # fscking linux.  There's a damn good reason why bash isn't a
    # suitable replacement for sh and here's an example.
    if( !open LS, "tcsh -c 'ssh -n $server[0] \"ls -l $server[1] | grep $logprefix\"'|" ) {
      stats::log($project,128+2+1,"Unable to contact log source!");
      return "","",0;
    } 
  } else {
    if( !open LS, "ls -l $server[0] | grep $logprefix |" ) {
      stats::log($project,128+2+1,"Unable to contact log source!");
      return "","",0;
    } 
  }

  my $linecount = 0;
  my $qualcount = 0;

  my ($logfilter, $datestr);
  my $yyyy = (gmtime(time-3600))[5]+1900;
  my $mm = (gmtime(time-3600))[4]+1;
  my $dd = (gmtime(time-3600))[3];
  my $hh = (gmtime(time-3600))[2];
  if($statsconf::dailyonly) {
    # The - is to ensure we ignore directories. We also test for permissions
    $logfilter = "-(...)(...)(...).*$logprefix(\\d\\d\\d\\d\\d\\d\\d\\d)(.*)";
    $datestr = sprintf("%04s%02s%02s", $yyyy, $mm, $dd);
  } else {
    # The - is to ensure we ignore directories. We also test for permissions
    $logfilter = "-(...)(...)(...).*$logprefix(\\d\\d\\d\\d\\d\\d\\d\\d-\\d\\d)(.*)";
    $datestr = sprintf("%04s%02s%02s-%02s", $yyyy, $mm, $dd, $hh);
  }
  stats::debug (5,"log filter: $logfilter\n");

  while (<LS>) {
    stats::debug (8,"log directory entry: $_");
    if( $_ =~ /$logfilter/ ) {
      stats::debug (9,"logfile match 1: $1 2: $2 3: $3 4: $4 5: $5\n");
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
            stats::log($project,128+2+1,"I need to load log $lastdate, but I cannot because the master created it with the wrong permissions!");
            die;
          }
          print $_;
          if(! ($_ =~ /(gz|bz2)$/) ) {
            stats::log($project,128+2+1,"The master failed to compress the $lastdate logfile.  Skipping to next project.");
            return "","",0;
          }
          $logtoload = $lastdate;
          $logext = $lastext;
        }
      }
    }
    $linecount++;
  }

  if($linecount == 0) {
    stats::log($project,128+2+1,"No log files found!");
    return "","",0;
  }

  if($qualcount == 1) {
    stats::log($project,1,"There are $linecount logs on the master, $qualcount is new to me.  Might as well load it while I'm thinking about it.");
  } elsif($qualcount > 1) {
    stats::log($project,1,"There are $linecount logs on the master, $qualcount are new to me.  I think I'll start with $logtoload.");
  }

  return $logtoload,$logext,$qualcount;
}

#
# scp
#
sub scp ($$$$$) {
  my ($project, $workdir, $server, $fullfn, $basefn) = @_;
  # Get list of logs that are on the master
  # Accepts:
  #   $workdir
  #   $fullfn
  #
  # Returns
  #   Nothing
  my $outbuf = "";
  my $command;

  if (defined($$server[0])) {
    $command = "scp -Bv $$server[0]:$fullfn $workdir 2> /dev/stdout |";
  } else {
    $command =  "scp -Bv $fullfn $workdir 2> /dev/stdout |";
  }
  stats::debug(7, "SCP command: $command");
  open SCP, "$command\n";

  while (<SCP>) {
    stats::debug(5, "SCP output: $_");
    if ($_ =~ /Transferred: stdin \d+, stdout \d+, stderr \d+ bytes in (\d+.\d) seconds/) {
      my $size = -s "$workdir$basefn";
      my $rate = rate_calc($size,$1);
      $size = num_format($size);
      my $time = num_format($1);
      $outbuf = "$basefn received: $size bytes in $time seconds ($rate)";
    }
  }
  close SCP;
  if ($outbuf eq "") {
    stats::log($project,1,"$basefn received");
  } else {
    stats::log($project,1,$outbuf);
  }
}

#
# uncompress
#
sub uncompress ($$$$) {
  my ( $project, $workdir, $basefn, $logext ) = @_;
  # Get list of logs that are on the master
  # Accepts:
  #   $workdir
  #   $basefn
  #   $logext
  #
  # Returns
  #   Raw filename (empty if an error occured)

  my $rawfn;
  my $compression;

  if ( $logext =~ /.gz$/ ) {
    my $command = "gzip -dv $workdir$basefn 2> /dev/stdout |";
    stats::debug(5, "GZIP command: $command\n");
    open GZIP, $command;
    while (<GZIP>) {
      stats::debug(5, "GZIP output: $_");
      if ($_ =~ /$basefn:[ \s]+(\d+.\d)% -- replaced with (.*)$/) {
        $compression = $1;
        $rawfn = $2;
        $rawfn =~ s/$workdir//;
        stats::log($project,1,"$basefn successfully decompressed ($compression% compression)");
      }
    }
    close GZIP;
  } elsif ( $logext =~ /.bz2$/ ) {
    my $orgsize = -s "$workdir$basefn";
    system("bzip2 -d $workdir$basefn");
    if ($? == 0) {
      $rawfn = $basefn;
      $rawfn =~ s/.bz2//i;
      my $newsize = -s "$workdir$rawfn";
      if ( $newsize == 0 ) {
        stats::log($project,1,"$basefn successfully decompressed, and the file is empty.");
      } else {
        stats::log($project,1,"$basefn successfully decompressed (" . int((1-$orgsize/$newsize)*100) . "% compression)");
      }
    }
  }
  return $rawfn;
}

#
# filter
#
sub filter ($$$$) {
  my ( $project, $workdir, $rawfn, $prefilter ) = @_;
  # Get list of logs that are on the master
  #
  # Returns
  #   final filename

  my $logdir = $statsconf::logdir{$project};
  my $finalfn = "$rawfn.filtered";
  if( $prefilter eq "" ) {
    stats::log($project,0,"There is no log filter for this project, proceeding to bcp.");
    $finalfn = $rawfn;
  } else {
    `echo $rawfn >> $logdir/filter_$project.err`;
    `cat $workdir$rawfn | $prefilter > $workdir$finalfn 2>> $logdir/filter_$project.err`;
    if ($? == 0) {
        stats::log($project,1,"$rawfn successfully filtered through $prefilter.");
    } else {
        stats::log($project,128+2+1,"unable to filter $rawfn through $prefilter!");
        die;
    }
  }
  return $finalfn;
}

#
# bcp
#
sub bcp ($$$$) {
  my ( $project, $workdir, $finalfn, $database ) = @_;
  # Bulk copy data into the database
  #
  # Returns
  #   Number of rows copied

  my $bcprows = `cat $workdir$finalfn | wc -l`;
  $bcprows =~ s/ +//g;
  chomp $bcprows;

  my $bcp = `time ./bcp.sh $database $workdir$finalfn 2>&1`;
  if($? != 0) {
    print "bcp error: $bcp\n";
    stats::log($project,128+8+2+1,"Error launching BCP, aborting hourly run.");
    die;
  }

  $bcp =~ /([0123456789.]+)/;
  my $rate = int($bcprows / $1);

  stats::log($project,1,"$finalfn successfully BCP'd into $database; $bcprows rows at $rate rows/second.");


  if($bcprows == 0) {
    stats::log($project,128+2+1,"No rows were imported for $finalfn;  Unless this was intentional, there's probably a problem.  I'm not going to abort, though.");
  }

  return $bcprows;
}

#
# process
#
sub process ($$$$$) {
  my ( $project, $workdir, $basefn, $yyyymmdd, $hh ) = @_;
  # Runs SQL-based processing
  #
  # Returns
  #   Number of rows processed
  #   Number of rows skipped

  my $bufstorage = "";
  my $psqlsuccess = 0;
  my $sqlrows = 0;
  my $skippedrows = 0;
  my $cmd = "psql -d $statsconf::database -f integrate.sql -v ProjectType=\\'$project\\' -v LogDate=\\'$yyyymmdd\\' -v HourNumber=\\'$hh\\' 2> /dev/stdout |";

  stats::debug (5,"process: command: $cmd\n");
  if(!open SQL, $cmd) {
    stats::log($project,128+8+2+1,"Error launching psql, aborting hourly run.");
    die;
  }
  while (<SQL>) {
    my $buf = sprintf("[%02s:%02s:%02s]",(gmtime)[2],(gmtime)[1],(gmtime)[0]) . $_;
    chomp $buf;
    if ( $buf ne '') {
      stats::log($project,0,$buf);
      $bufstorage = "$bufstorage$buf\n";
    }
    if( $_ =~ /^Msg|ERROR/ ) {
      $psqlsuccess = 1;
    } elsif ( $_ =~ /^ Total rows: *(\d+)/ ) {
      $sqlrows = $1;
    } elsif ( $_ =~ /^ Skipped *(\d+) rows from project/ ) {
      $skippedrows = $1;

      # Don't do this before grabbing $1
      s/^ *//;
      if ( $skippedrows != 0 ) {
        stats::log($project,1,"$_");
      }
    }
  }
  close SQL;
  if( $psqlsuccess > 0) {
    stats::log($project,128+8+2+1,"integrate.sql failed on $basefn - aborting.  Details are in $workdir/psql_errors");
    open SQERR, ">$workdir/psql_errors";
    print SQERR "$bufstorage";
    close SQERR;
    die;
  }

  return $sqlrows, $skippedrows;
}

#
# logdb_lock
#

sub logdb_lock ($$$) {
  my ($project, $yyyymmdd, $hh) = @_;
  local $logdbh->{RaiseError} = 0;  # localize and turn off for this block
  local $logdbh->{AutoCommit} = 1;  # localize and turn on for this block
  # "Locks" a record in logdb.  This should not be confused with
  # real semaphores
  #
  # Returns {SUCCESS|FAIL_STARTEDs|FAIL_FINISHED}
  # FAIL_STARTED means the log was started but has not (yet) been finished
  # FAIL_FINISHED means the log was started and finished
  
  my $lockcmd = qq(
    INSERT INTO history(project,logday,loghour,starttime)
      VALUES (?,?,?, now()::timestamp)
  );
  $lockstd = $logdbh->prepare($lockcmd);

  if ($locksth->execute($project, $yyyymmdd, $hh)) {
    $locksth->finish;
    return "SUCCESS";
  } else {
    $histsth = $logdbh->prepare(q(
      SELECT project,logday,loghour,starttime,endtime
        FROM history
        WHERE project=?
        AND logday=?
        AND loghour=?));
    $histsth->execute($project, $yyyymmdd, $hh);
    if ($histsth->rows != 1) {
      stats::log($project,128+8+2+1,"Two rows found in history for $project, $yyyymmdd, $hh. Aborting.");
      die;
    }

    ($rproject,$rlogday,$rloghour,$rstarttime,$rendtime) = $histsth->fetchrow_array;
    $histsth->finish;
    $locksth->finish;
    if ($rendtime == '') {
      return "FAIL_STARTED";
    } else {
      return "FAIL_FINISHED";
    };

    # We shouldn't reach here
  }
};

#
# process logdb
#
sub process_logdb ($$$$$) {
  my ( $project, $workdir, $basefn, $yyyymmdd, $hh ) = @_;
  # Runs SQL-based processing for logdb
  #
  # Returns
  #   Number of rows processed
  #   Number of rows skipped

  my $bufstorage = "";
  my $psqlsuccess = 0;
  my $sqlrows = 0;
  my $skippedrows = 0;
  my $cmd = "psql -d $statsconf::database -f integrate.sql -v ProjectType=\\'$project\\' -v LogDate=\\'$yyyymmdd\\' -v HourNumber=\\'$hh\\' 2> /dev/stdout |";

  stats::debug (5,"process: command: $cmd\n");
  if(!open SQL, $cmd) {
    stats::log($project,128+8+2+1,"Error launching psql, aborting hourly run.");
    die;
  }
  while (<SQL>) {
    my $buf = sprintf("[%02s:%02s:%02s]",(gmtime)[2],(gmtime)[1],(gmtime)[0]) . $_;
    chomp $buf;
    if ( $buf ne '') {
      stats::log($project,0,$buf);
      $bufstorage = "$bufstorage$buf\n";
    }
    if( $_ =~ /^Msg|ERROR/ ) {
      $psqlsuccess = 1;
    } elsif ( $_ =~ /^ Total rows: *(\d+)/ ) {
      $sqlrows = $1;
    } elsif ( $_ =~ /^ Skipped *(\d+) rows from project/ ) {
      $skippedrows = $1;

      # Don't do this before grabbing $1
      s/^ *//;
      if ( $skippedrows != 0 ) {
        stats::log($project,1,"$_");
      }
    }
  }
  close SQL;
  if( $psqlsuccess > 0) {
    stats::log($project,128+8+2+1,"integrate.sql failed on $basefn - aborting.  Details are in $workdir/psql_errors");
    open SQERR, ">$workdir/psql_errors";
    print SQERR "$bufstorage";
    close SQERR;
    die;
  }

  return $sqlrows, $skippedrows;
}

#
# num_format
#
sub num_format ($) {
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

#
# rate_calc
#
sub rate_calc ($$) {
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

#
# main
#

$statsconf::dailyonly = 0 if ! defined $statsconf::dailyonly;
stats::debug( 1, "CONFIG: " . ($statsconf::dailyonly ? "don't " : "") . "expect daily-only logs (statsconf::dailyonly=$statsconf::dailyonly)\n" );

$statsconf::allow_missing_logs = 0 if ! defined $statsconf::allow_missing_logs;
stats::debug( 1, "CONFIG: " . ($statsconf::allow_missing_logs ? "don't " : "") . "allow missing logs (statsconf::allow_missing_logs=$statsconf::allow_missing_logs)\n" );

my $respawn = 1;

($ENV{'HOME'} . '/workdir/hourly/') =~ /([A-Za-z0-9_\-\/]+)/;
my $workdir = $1;
if(! -d $workdir) {
  stats::log("stats",128+2+1,"Hey! Someone needs to mkdir $workdir!");
  die;
}

while ($respawn and not -e 'stop') {
  $respawn = 0;
  RUNPROJECTS: for (my $i = 0; $i < @statsconf::projects; $i++) {
    my $project = $statsconf::projects[$i];
    stats::debug (1,"project: $project\n");
    
    # Check to see if we're locked, but don't set it until it's time to actually do some work
    #
    # NOTE:
    # This means that anything that actually modifies data should not happen until after we set
    # the lock.
    if ($_ = stats::semcheck('hourly')) {
      stats::log($project,129,"Cannot obtain lock for hourly.pl!  [$_] still running!");
      #next RUNPROJECTS;
      die;
    }

    my $prefilter = $statsconf::prefilter{$project};

    my $logprefix = $project;
    if(defined($statsconf::logprefix{$project})) {
      $logprefix = $statsconf::logprefix{$project};
      stats::debug (2, "custom log prefix '$logprefix' used for project $project\n");
    }

    my $sourcelist = $statsconf::logsource{$project};
    stats::debug(2,"sourcelist: $sourcelist\n");
    my @server = split /:/, $sourcelist;
    if(!defined($server[1])) {
      $server[1] = $server[0];
      undef $server[0];
    }
    $server[1] .= "/";

    # Check to see if workdir is empty
    opendir WD, "$workdir" or die "Unable to open working directory $workdir";
    my @wdcontents = grep !/^(CVS|\.\.?)$/, readdir WD;
    closedir WD;

    if(@wdcontents > 0) {
      stats::log($project,128+2+1,"Workdir is not empty!  I refuse to proceed with hourly processing.");
      die;
    }

    my ($logtoload,$logext,$qualcount) = findlog($project, $logprefix);
    stats::debug(4, "findlog returned logtoload: '$logtoload' logext: '$logext' qualcount: $qualcount\n");

    if( $qualcount > 0 ) {
      my ($yyyymmdd, $hh) = split /-/, $logtoload;
      if (! defined($hh) ) {
        $hh = '23';
      }

      my $lastday = stats::lastday($project);
      chomp $lastday;

      if ($lastday eq "") {
        stats::log($project,128+2+1,"Warning: It appears that there has never been a daily run for this project.");
      } else {
        my $lasttime = timegm(0,0,0,(substr $lastday, 6, 2),((substr $lastday, 4, 2)-1),(substr $lastday, 0, 4));
        my $logtime = timegm(0,0,0,(substr $yyyymmdd, 6, 2),((substr $yyyymmdd, 4, 2)-1),(substr $yyyymmdd, 0, 4));
    
        if ( $lasttime != ($logtime - 86400)) {
          if ( not $statsconf::allow_missing_logs ) {
            stats::debug(8, "allow_missing_logs=$statsconf::allow_missing_logs\n");
            stats::log($project,128+8+2+1,"Aborting: I'm supposed to load a log from $yyyymmdd, but my last daily processing run was for $lastday!");
            die;
          } else {
            stats::log($project,128+8+2+1,"I'm supposed to load a log from $yyyymmdd, but the last daily processing run was for $lastday. Just thought you'd like to know!");
          }
        }
      }

      if($qualcount > 1) {
         # We should respawn at the end to catch up...
         $respawn = 1;
      }

      my $fullfn = "$server[1]$logprefix$logtoload$logext";
      my $basefn = "$logprefix$logtoload$logext";

      # Go ahead and set the lock now
      if($_ = stats::semflag('hourly',"hourly.pl") ne "OK") {
        stats::log($project,129,"Cannot obtain lock for hourly.pl!  [$_] still running!");
        die;
      }

      scp($project, $workdir, \@server, $fullfn, $basefn);

      my $rawfn = uncompress( $project, $workdir, $basefn, $logext );
      if( $rawfn eq "" ) {
        stats::log($project,128+8+2+1,"$basefn failed decompression!");
      } else {

      #Load log into log db.
      if ($statsconf::logdb) {
          my $logproject = "logdb";
          my $finalfn = filter( $logproject, $workdir, $rawfn, $statsconf::logdb{prefilter} );
          my $bcprows = bcp( $logproject, $workdir, $finalfn, $statsconf::logdatabase );
          my ( $sqlrows, $skippedrows ) = process_logdb( $project, $workdir, $basefn, $yyyymmdd, $hh );
          # perform sanity checking here
          if ( ( $sqlrows + $skippedrows ) != $bcprows ) {
            stats::log($project,128+8+2+1,"Row counts for BCP($bcprows) and SQL( $sqlrows + $skippedrows ) do not match, aborting.");
            die;
          }
          stats::log($project,1,"$basefn successfully processed into $logproject.");

      }

        #Now do the real processing
        my $finalfn = filter( $project, $workdir, $rawfn, $prefilter );

        my $bcprows = bcp( $project, $workdir, $finalfn, $statsconf::database );

        my ( $sqlrows, $skippedrows ) = process( $project, $workdir, $basefn, $yyyymmdd, $hh );

        # perform sanity checking here
        if ( ( $sqlrows + $skippedrows ) != $bcprows ) {
          stats::log($project,128+8+2+1,"Row counts for BCP($bcprows) and SQL( $sqlrows + $skippedrows ) do not match, aborting.");
          die;
        }
        stats::log($project,1,"$basefn successfully processed.");

        # It's always good to clean up after ourselves for the next run.
        unlink "$workdir$finalfn", "$workdir$rawfn";

        if($hh == 23) {
          if(stats::lastday($project) lt $yyyymmdd) {
            # Note -- CWD is not clean after calling spawn_daily.  Always use absolute
            # Paths after calling this.  (yeah, I know that's ugly)
            spawn_daily($project);
          }
        }
      }
    }
    if(stats::semflag('hourly') ne "OK") {
      stats::log($project,128+8+2+1,"Error clearing hourly.pl lock");
      die;
    }
  }
}

print "stop file exists; exiting\n" if -e 'stop';
exit 0;

# vi:expandtab sw=2 ts=2

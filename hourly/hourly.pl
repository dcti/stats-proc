#!/usr/bin/perl -Tw -I../global
#
# $Id: hourly.pl,v 1.63 2000/09/13 07:36:07 decibel Exp $
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
# Without it, the script is unable to spawn bcp or sqsh claiming the inability
# to access /dev/stderr.  *shrug*

use strict;
$ENV{PATH} = '/usr/local/bin:/usr/bin:/bin:/opt/sybase/bin';

#$0 =~ /(.*\/)([^\/]+)/;
#my $cwd = $1;
#my $me = $2;
#chdir $cwd;

use statsconf;
use stats;

use Time::Local;

my $yyyy = (gmtime(time-3600))[5]+1900;
my $mm = (gmtime(time-3600))[4]+1;
my $dd = (gmtime(time-3600))[3];
my $hh = (gmtime(time-3600))[2];
my $datestr = sprintf("%04s%02s%02s-%02s", $yyyy, $mm, $dd, $hh);

my $respawn = 0;

my $workdir = "./workdir/";

for (my $i = 0; $i < @statsconf::projects; $i++) {
  my $project = $statsconf::projects[$i];
  # This is a big-time kludge to make sure we don't walk on the RC5 run
  if (-e '/home/incoming/newlogs-rc5/nologs.lck') {
    stats::log($project,1,'/usr/home/incoming/newlogs-rc5/nologs.lck exists; aborting.');
    die;
  }
  
  # Check to see if we're locked, but don't set it until it's time to actually do some work
  #
  # NOTE:
  # This means that anything that actually modifies data should not happen until after we set
  # the lock.
  if ($_ = stats::semcheck($project)) {
    stats::log($project,131,"Cannot obtain lock for hourly.pl!  [$_] still running!");
    die;
  }
  my $sourcelist = $statsconf::logsource{$project};
  my $prefilter = $statsconf::prefilter{$project};
  my $lastlog = stats::lastlog($project,"get");
  my $logtoload = "29991231-23";
  my $outbuf = "";
  my @server = split /:/, $sourcelist;
  chomp($lastlog);

  opendir WD, "$workdir" or die;
  my @wdcontents = grep !/^(CVS|\.\.?)$/, readdir WD;
  closedir WD;

  if(@wdcontents > 0) {
    stats::log($project,131,"Workdir is not empty!  I refuse to proceed with hourly processing.");
    die;
  }

  stats::log($project,1,"Looking for new logs, last log processed was $lastlog");

  # fscking linux.  There's a damn good reason why bash isn't a
  # suitable replacement for sh and here's an example.
 
  open LS, "tcsh -c 'ssh $server[0] \"ls -l $server[1]$project*.log*\"'|";
  my $linecount = 0;
  my $qualcount = 0;

  while (<LS>) {
    if( $_ =~ /-(...)(...)(...).*$project(\d\d\d\d\d\d\d\d-\d\d)/ ) {
      my $lastdate = $4;

      if($lastdate gt $lastlog) {
        $qualcount++;
        if($lastdate gt $datestr) {
          # This log is the "active" log, we don't want to count it in our summary.
          $qualcount--;
        }
        if(($lastdate lt $logtoload) and ($lastdate le $datestr)) {
          if(! ($2 =~ /r/) ) {
            stats::log($project,131,"I need to load log $4, but I cannot because the master created it with the wrong permissions!");
            die;
          }
          print $_;
          if(! ($_ =~ /gz$/) ) {
            stats::log($project,131,"The master failed to compress the $4 logfile.  Aborting.");
            die;
          }
          $logtoload = $lastdate;
        }
      }
    }
    $linecount++;
  }

  if($linecount == 0) {
    stats::log($project,131,"Unable to contact log source!");
  }

  if( $logtoload le $datestr ) {
    if($qualcount == 1) {
      stats::log($project,1,"There are $linecount logs on the master, $qualcount is new to me.  Might as well load it while I'm thinking about it.");
    } else {
      stats::log($project,1,"There are $linecount logs on the master, $qualcount are new to me.  I think I'll start with $logtoload.");
    }

    my ($yyyymmdd, $hh) = split /-/, $logtoload;

    my $lastday = stats::lastday($project);
    chomp $lastday;

    my $lasttime = timegm(0,0,0,(substr $lastday, 6, 2),((substr $lastday, 4, 2)-1),(substr $lastday, 0, 4));
    my $logtime = timegm(0,0,0,(substr $yyyymmdd, 6, 2),((substr $yyyymmdd, 4, 2)-1),(substr $yyyymmdd, 0, 4));

    if ( $lasttime != ($logtime - 86400)) {
      stats::log($project,131,"Aborting: I'm supposed to load a log from $yyyymmdd, but my last daily processing run was for $lastday!");
      die;
    }

    if($qualcount > 1) {
       # We should respawn at the end to catch up...
       $respawn = 1;
    }

    my $fullfn = "$server[1]$project$logtoload.log.gz";
    my $basefn = "$project$logtoload.log.gz";

    # Go ahead and set the lock now
    if($_ = stats::semflag($project,"hourly.pl") ne "OK") {
      stats::log($project,131,"Cannot obtain lock for hourly.pl!  [$_] still running!");
      die;
    }

    $outbuf = "";
    open SCP, "scp -Bv $server[0]:$fullfn $workdir 2> /dev/stdout |";
    while (<SCP>) {
      if ($_ =~ /Transferred: stdin (\d+), stdout (\d+), stderr (\d+) bytes in (\d+.\d) seconds/) {
        my $rate = rate_calc($2,$4);
        my $size = num_format($2);
        my $time = num_format($4);
        $outbuf = "$basefn received: $size bytes in $time seconds ($rate)\n";
      }
    }
    close SCP;
    stats::log($project,1,$outbuf);

    open GZIP, "gzip -dv $workdir$basefn 2> /dev/stdout |";
    my $rawfn = "";
    while (<GZIP>) {
      if ($_ =~ /$basefn:[ \s]+(\d+.\d)% -- replaced with (.*)$/) {
        $rawfn = $2;
        stats::log($project,1,"$basefn successfully decompressed ($1% compression)");
      }
    }
    if( $rawfn eq "" ) {
      stats::log($project,130,"$basefn failed decompression!");
    } else {
      my $finalfn = "$rawfn.filtered";
      if( $prefilter eq "" ) {
        stats::log($project,0,"There is no log filter for this project, proceeding to bcp.");
        $finalfn = $rawfn;
      } else {
	`$prefilter $rawfn > $finalfn 2>> ./filter_$project.err`;
        stats::log($project,1,"$basefn successfully filtered through $prefilter.");
      }

      open BCP, "bcp import_bcp in $finalfn -e$workdir\\bcp_errors -S$statsconf::sqlserver -U$statsconf::sqllogin -P$statsconf::sqlpasswd -c -t, 2> /dev/stderr |";

      if(!<BCP>) {
        stats::log($project,131,"Error launching BCP, aborting hourly run.");
        die;
      }

      my $rows = 0;
      my $rate = 0;

      while (<BCP>) {
	my $buf = $_;
        chomp $buf;

        if ($buf =~ /(\d+) rows copied/) {
          $rows = num_format($1);
        } elsif ($buf =~ /(\d+\.\d+) rows per sec/) {
	  $rate = num_format($1);
	  print "\n";
	  stats::log($project,1,"$finalfn successfully BCP'd; $rows rows at $rate rows/second.");
	} elsif ($buf =~ /\d+ rows sent to SQL Server./) {
	  print ".";
	} else {
	  print $buf;
	}
      }
      close BCP;

      $rows =~ s/,//g;

      if($rows == 0) {
        stats::log($project,131,"No rows were imported for $finalfn;  Unless this was intentional, there's probably a problem.  I'm not going to abort, though.");
        die;
      }

      opendir WD, "$workdir" or die;
      my @wdcontents = grep /bcp_errors/, readdir WD;
      closedir WD;

      if(@wdcontents > 0) {
        stats::log($project,131,"Errors encountered during BCP!  Check bcp_errors file.  Aborting.");
        die;
      }

      my $bufstorage = "";
      my $sqshsuccess = 0;
      open SQL, "sqsh -S$statsconf::sqlserver -U$statsconf::sqllogin -P$statsconf::sqlpasswd -i integrate.sql 2> /dev/stderr |";

      if(!<SQL>) {
        stats::log($project,131,"Error launching sqsh, aborting hourly run.");
        die;
      }
      while (<SQL>) {
	my $ts = sprintf("[%02s:%02s:%02s]",(gmtime)[2],(gmtime)[1],(gmtime)[0]);
        print "$ts $_";
        $bufstorage = "$bufstorage$ts $_";
        if( $_ =~ /^Msg/ ) {
          $sqshsuccess = 1;
        }
      }
      close SQL;
      if( $sqshsuccess > 0) {
        stats::log($project,131,"integrate.sql failed on $basefn - aborting.  Details are in $workdir\sqsh_errors");
        open SQERR, ">$workdir\sqsh_errors";
        print SQERR "$bufstorage";
        close SQERR;
        die;
      }

      # perform sanity checking here
      stats::log($project,1,"$basefn successfully processed.");

      # It's always good to clean up after ourselves for the next run.
      unlink $finalfn, $rawfn;

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
  if(stats::semflag($project) ne "OK") {
    stats::log($project,131,"Error clearing hourly.pl lock");
    die;
  }
}

if ($respawn > 0) {
  exec "./hourly.pl";
}

sub spawn_daily {

  my ($f_project) = @_;
  chdir "../daily/";
  stats::log($f_project,1,"Spawning daily.pl for $f_project");
  system "./daily.pl $f_project";
  stats::log($f_project,1,"daily.pl complete for $f_project");

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

#!/usr/bin/perl -Tw -I../global
#
# $Id: hourly.pl,v 1.35 2000/07/20 00:32:47 decibel Exp $

use strict;
$ENV{PATH} = '/usr/local/bin:/usr/bin:/bin:/opt/sybase/bin';
use statsconf;
use stats;

my $yyyy = (gmtime(time-3600))[5]+1900;
my $mm = (gmtime(time-3600))[4]+1;
my $dd = (gmtime(time-3600))[3];
my $hh = (gmtime(time-3600))[2];
my $datestr = sprintf("%04s%02s%02s-%02s", $yyyy, $mm, $dd, $hh);

my $workdir = "./workdir/";

for (my $i = 0; $i < @statsconf::projects; $i++) {
  my $project = $statsconf::projects[$i];
  my $sourcelist = $statsconf::logsource{$project};
  my $prefilter = $statsconf::prefilter{$project};
  my $lastlog = lastlog($project,"get");
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
 
  open LS, "tcsh -c 'ssh $server[0] \"ls $server[1]$project*.log.gz\"'|";
  my $linecount = 0;
  my $qualcount = 0;

  while (<LS>) {
    if( $_ =~ /.*\/$project(\d\d\d\d\d\d\d\d-\d\d)/ ) {
      my $lastdate = $1;

      if($lastdate gt $lastlog) {
        $qualcount++;
        if($lastdate lt $logtoload) {
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
    stats::log($project,1,"There are $linecount logs on the master, $qualcount are new to me.  I think I'll start with $logtoload.");
    my $fullfn = "$server[1]$project$logtoload.log.gz";
    my $basefn = "$project$logtoload.log.gz";

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
      while (<SQL>) {
	my $ts = sprintf("[%02s:%02s:%02s]",(localtime)[2],(localtime)[1],(localtime)[0]);
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

      # If hour = 23 or day > lastlog(day)
      # queue daily processing for this project

      # It's always good to clean up after ourselves for the next run.
      unlink $finalfn, $rawfn;

      lastlog($project,$logtoload);
    }
    close GZIP;
  }
}

sub lastlog {
  # This function will either return or store the lastlog value for the specified project.
  #
  # lastlog("ogr","get") will return lastlog value.
  # lastlog("ogr","20001231-01") will set lastlog value to 31-Dec-2000 01:00 UTC

  my ($f_project, $f_action) = @_;

  if( $f_action =~ /get/i) {
    return `cat ~/var/lastlog.$f_project`;
  } else {
    return `echo $f_action > ~/var/lastlog.$f_project`;
  }
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

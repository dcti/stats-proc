#!/usr/bin/perl -w 
use strict;
$ENV{PATH} = '/usr/local/bin:/usr/bin:/bin:/opt/sybase/bin';
use stats;

# Don't know if this is the best place for this stuff to live
my $sqllogin = "-Ustatproc";
my $sqlpasswd = "-PPASSWORD";
my $sqlserver = "-STALLY";

my $yyyy = (gmtime(time-3600))[5]+1900;
my $mm = (gmtime(time-3600))[4]+1;
my $dd = (gmtime(time-3600))[3];
my $hh = (gmtime(time-3600))[2];
my $datestr = sprintf("%04s%02s%02s-%02s", $yyyy, $mm, $dd, $hh);

my $workdir = "./workdir/";

# This could easily be populated from somewhere else.
# I don't see a big downside to simply hard-coding, however.

#my @projectlist = ("ogr",
#                   "rc5");
#my @sourcelist  = ("LOGS-SOURCE.FQDN:/home/master/logs/",
#                   "LOGS-SOURCE.FQDN:/home/master/logs/");
#my @prefilter   = ("./logmod_ogr.pl",
#                   "./logmod_rc5.pl");

my @projectlist = ("ogr");
my @sourcelist  = ("n0:/home/decibel/logs/");
my @prefilter   = ("./logmod_ogr.pl");

# Insert code here to look for droppings in $workdir

`rm $workdir*`;

for (my $i = 0; $i < @projectlist; $i++) {
  my $project = $projectlist[$i];
  my $lastlog = lastlog($project,"get");
  my $logtoload = "29991231-23";
  my $outbuf = "";
  my @server = split /:/, $sourcelist[$i];
  chomp($lastlog);

  stats::log($project,1,"Looking for new logs, last log processed was $lastlog");

  # fscking linux.  There's a damn good reason why bash isn't a
  # suitable replacement for sh and here's an example.
 
  open LS, "tcsh -c 'ssh $server[0] \"ls $server[1]$project*\"'|";
  my $linecount = 0;
  my $qualcount = 0;

  while (<LS>) {
    print $_;
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

  if( $logtoload lt $datestr ) {
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
      if( $prefilter[$i] eq "" ) {
        stats::log($project,0,"There is no log filter for this project, proceeding to bcp.");
        $finalfn = $rawfn;
      } else {
        `cat $rawfn | $prefilter[$i] > $finalfn`;
        stats::log($project,1,"$basefn successfully filtered through $prefilter[$i].");
      }

      open BCP, "bcp import_bcp in $finalfn -ebcp_errors $sqlserver $sqllogin $sqlpasswd -c -t, 2> /dev/stderr |";

      my $rows = 0;
      my $rate = 0;

      while (<BCP>) {
	my $buf = $_;
        print $buf;
        chomp $buf;

        if ($buf =~ /(\d+) rows copied/) {
          $rows = num_format($1);
        }

	if ($buf =~ /(\d+\.\d+) rows per sec/) {
	  $rate = num_format($1);
	  stats::log($project,1,"$finalfn successfully BCP'd; $rows rows at $rate rows/second.");
	}
      }
      close BCP;

      # call bruce's code here
      #open SQL, "sqsh $sqlserver $sqllogin $sqlpasswd -i integrate.sql 24 2> /dev/stderr |";
      #  while (<SQL>) {
      #  print $_;
      #}

      # perform sanity checking here

      # If hour = 23 or day > lastlog(day)
      # queue daily processing for this project

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

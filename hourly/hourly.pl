#!/usr/bin/perl -w 
use strict;
$ENV{PATH} = '/usr/local/bin:/usr/bin:/bin:/opt/sybase/bin';
use stats;

my $yyyy = (gmtime(time-3600))[5]+1900;
my $mm = (gmtime(time-3600))[4]+1;
my $dd = (gmtime(time-3600))[3];
my $hh = (gmtime(time-3600))[2];
my $datestr = sprintf("%04s%02s%02s-%02s", $yyyy, $mm, $dd, $hh);

my $workdir = "./workdir/";

my @projectlist = ("ogr",
                   "rc5");
my @sourcelist  = ("LOGS-SOURCE-FQDN:/home/master/logs/",
                   "LOGS-SOURCE-FQDN:/home/master/logs/");
my @prefilter   = ("./logmod_ogr.pl",
                   "");

# Insert code here to look for droppings in $workdir

`rm $workdir*`;

for (my $i = 1; $i < @projectlist; $i++) {
  my $project = $projectlist[$i];
  my $lastlog = `cat ~/var/lastlog.$project`;
  my $logtoload = "29991231-23";
  my @server = split /:/, $sourcelist[$i];
  chomp($lastlog);

  print "Project $i is $project.\nMy last log was $lastlog\n";

  open LS, "tcsh -c 'ssh $server[0] \"ls $server[1]$project*\"'|";
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
  if( $logtoload lt $datestr ) {
    print "Of $linecount logs available, $qualcount need to be loaded.  Next up is $logtoload.\n";
    my $fullfn = "$server[1]$project$logtoload.log.gz";
    my $basefn = "$project$logtoload.log.gz";

    print "Retrieving $fullfn: ";
    open SCP, "scp -Bv $server[0]:$fullfn $workdir 2> /dev/stdout |";
    while (<SCP>) {
      if ($_ =~ /Transferred: stdin (\d+), stdout (\d+), stderr (\d+) bytes in (\d+.\d) seconds/) {
        my $rate = rate_calc($2,$4);
        my $size = num_format($2);
        my $time = num_format($4);
        print "Received $size bytes in $time seconds ($rate)\n";
      }
    }
    close SCP;

    print "Decompressing $basefn";
    open GZIP, "gzip -dv $workdir$basefn 2> /dev/stdout |";
    my $rawfn = "";
    while (<GZIP>) {
      if ($_ =~ /$basefn:[ \s]+(\d+.\d)% -- replaced with (.*)$/) {
        print "-->$2 ($1% compression)\n";
        $rawfn = $2;
      }
    }
    if( $rawfn eq "" ) {
      print ": gzip failed!\n";
    } else {
      my $finalfn = "$rawfn.filtered";
      if( $prefilter[$i] eq "" ) {
        print "There is no log filter for this project, proceeding to bcp.\n";
        $finalfn = $rawfn;
      } else {
        print "Filtering log through $prefilter[$i]\n";
        `cat $rawfn | $prefilter[$i] > $finalfn`;
      }
      # bcp goes here
    }
    print "\n";
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


#!/usr/bin/perl -Tw
use strict
$ENV{PATH} = '/usr/local/bin:/usr/bin:/bin';
use stats;

my $project = "rc5";
my $incoming = $stats::incoming{$project};
my $projectdir = $stats::projectdir{$project};

my $filespec = "$incoming/rc519990118-00.log.gz";

print "mv $filespec $projectdir\n";
 
system "mv", $filespec, $projectdir;

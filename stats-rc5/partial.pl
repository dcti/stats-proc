#!/usr/bin/perl -Tw
#
# $Id: partial.pl,v 1.1 2003/09/11 02:04:01 decibel Exp $
#

use strict
$ENV{PATH} = '/usr/local/sybase/bin:/usr/local/bin:/usr/bin:/bin';
use stats;

my $sqllogin = "-Ustatproc";
my $sqlpasswd = "-PTR2cod#";
my $sqlserver = "-SBLOWER";

my $project = "rc5";
my $incoming = $stats::incoming{$project};
my $projectdir = $stats::projectdir{$project};

my $yyyy = (localtime)[5]+1900;
my $mm = (localtime)[4]+1;
my $dd = (localtime)[3];
my $today = sprintf("%04s%02s%02s", $yyyy, $mm, $dd);

stats::log($project,129,"daily-$project re-started");

    $retcode = system "sqsh -i dp_newjoin.sql";
    stats::log($project,1,"Applied Retroactive Team Joins");

    $retcode = system "sqsh -i dp_em_rank.sql";
    stats::log($project,1,"Emails Ranking complete (Overall)");
    $retcode = system "sqsh -i dp_em_yrank.sql";
    stats::log($project,1,"Emails Ranking complete (Yesterday)");

    $retcode = system "sqsh -i dy_members.sql";
    stats::log($project,1,"CACHE_tm_MEMBERS table built");

    $retcode = system "sqsh -i dp_tm_rank.sql";
    stats::log($project,1,"Teams Ranking complete (Overall)");
    $retcode = system "sqsh -i dp_tm_yrank.sql";
    stats::log($project,1,"Teams Ranking complete (Yesterday)");
    
    $retcode = system "sqsh -i dy_dailyblocks.sql";
    stats::log($project,1,"CACHE_dailyblocks table built");

    $retcode = system "sudo pcpages";
    stats::log($project,1,"pc_web pages generated");

    system "rm $incoming/nologs.lck";

stats::log($project,129,"daily-$project ended");

#!/usr/bin/perl -Tw -I../global
#
# $Id: yoyo_join.pl,v 1.1 2008/05/07 14:22:03 thejet Exp $
#
# Automatically joins the yoyo.rechenkraft.net users to the Yoyo team.
#
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
delete $ENV{ENV};

#$0 =~ /(.*\/)([^\/]+)/;
#my $cwd = $1;
#my $me = $2;
#chdir $cwd;

use statsconf;
use stats;


($ENV{'HOME'} . '/workdir/hourly/') =~ /([A-Za-z0-9_\-\/]+)/;
my $workdir = $1;

my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime;

my $statsdate = "$mday-".$abbr[$mon]."-".($year + 1900);
print "$statsdate\n";

  my $bufstorage = "";
  my $psqlsuccess = 0;
  my $cmd = "psql -d $statsconf::database -f yoyo_join.sql -v StatsDate=\\'$statsdate\\' 2> /dev/stdout |";

  stats::debug (5,"process: command: $cmd\n");
  if(!open SQL, $cmd) {
    stats::log(0,128+8+2+1,"Error launching psql, aborting Yoyo join script.");
    die;
  }
  while (<SQL>) {
    my $buf = sprintf("[%02s:%02s:%02s]",(gmtime)[2],(gmtime)[1],(gmtime)[0]) . $_;
    chomp $buf;
    if ( $buf ne '') {
      stats::log(0,0,$buf);
      $bufstorage = "$bufstorage$buf\n";
    }
    if( $_ =~ /^Msg|ERROR/ ) {
      $psqlsuccess = 1;
    }
  }
  close SQL;

  if( $psqlsuccess > 0) {
    stats::log(0,128+8+2+1,"yoyo_join.sql failed - aborting.  Details are in $workdir/yoyo_psql_errors");
    open SQERR, ">$workdir/yoyo_psql_errors";
    print SQERR "$bufstorage";
    close SQERR;
    die;
  }

exit 0;


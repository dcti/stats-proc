#
# $Id: stats.pm,v 1.25 2002/06/10 06:14:48 decibel Exp $
#
# Stats global perl definitions/routines
#
# This should be world-readible from the production directory
# and symlinked someplace like /usr/lib/perl5 where it'll
# get caught in the perl include path.
#

package stats;

require IO::Socket;

sub log {

	# log ( project, dest, message)
	#
	# dest:	  0 - file (always on)
	#	  1 - #dcti-logs
	#	  2 - #dcti
	#	  4 - #distributed
	#	  8 - pagers
	#	 64 - Print to STDERR instead of STDOUT
	#	128 - High Priority

	my @par = @_;
	my $project = shift(@par);
	my $dest = shift(@par);
	my $logdir = $statsconf::logdir{$project};
	my $pass = "";

	my $dd = (localtime)[3];
	my $mm = (Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec)[(localtime)[4]];
	my $yy = (localtime)[5]+1900;
	my $hh = (localtime)[2];
	my $mi = (localtime)[1];
	my $sc = (localtime)[0];

	my $ts = sprintf("[%d-%s-%d %02s:%02s:%02s]",$dd,$mm,$yy,$hh,$mi,$sc);

	if (open LOGFILE, ">>$logdir$project.log") {
		print LOGFILE $ts," ",@par,"\n";
		close LOGFILE;
	} else {
		print "Unable to open [$logdir$project.log]!\n";
		print STDERR "Unable to open [$logdir$project.log]!\n";
	}

	if ($dest & 64) {
		print STDERR $ts," ",@par,"\n";
	} else {
		print $ts," ",@par,"\n";
	}


	# Cycle through configured irc channels and send to any that qualify
	for (my $i = 0; $i < @statsconf::ircchannels; $i++) {
		my ($bitmask,$channel,$port,$msg,$notify) = split /:/, $statsconf::ircchannels[$i];
		my $pass = $msg;
		if($dest & 128) {
			$pass = $notify;
		}
		if($dest & $bitmask) {
			DCTIeventsay($port, "$pass", "$project", @par);
		}
	}

	# Special "pagers" section
	if ($dest & 8) {
                #pagers

		#open PAGER, "|mail \"-s$statsconf::logtag/$project\" nugget-pager\@slacker.com";
		#print PAGER "@par\n";
                #close PAGER;

	}
}

sub DCTIeventsay {
	# 0 project
	# 1 port
	# 2 password
	# 3 message

	my $port = shift;
	my $password = shift;
	my $project = shift;
	my $message = shift;

	local $SIG{ALRM} = sub { die "timeout" };

	eval {
		alarm 5;
		my $iaddr = gethostbyname( $statsconf::dctievent ); 
		my $proto = getprotobyname('tcp') || die "getproto: $!\n";
		my $paddr = Socket::sockaddr_in($port, $iaddr);
		socket(S, &Socket::PF_INET, &Socket::SOCK_STREAM, $proto) || die "socket: $!";
		if(connect(S, $paddr)) {
			print S "$password: ($statsconf::logtag/$project) $message\n";
			close S;	
		} else {
			print "Could not reach $paddr";
		}
		alarm 0;
	};

	if($@) {
		if ($@ =~ /timeout/) {
			print "Connect to $statsconf::dctievent timed out\n";
			print STDERR "Connect to $statsconf::dctievent timed out trying to report ($statsconf::logtag/$project) $message\n";
			$@ = "";
		} else {
			alarm 0;
			die;
		}
	}
}

sub semflag {
	# project id
	# task at hand or NULL to signal clear

        my ($project, $task) = @_;

	my $lockfile = `echo "~/log/statsrun.lck"`;

	if($task) {
	    if(semcheck($project)) {
		# Can't set the lock if it already exists.
			return semcheck($project);
		} else {
			# Apply lock
			`echo "$task" > $lockfile`;
			return "OK";
		}
	} else {
		# Clear lock
		unlink $lockfile;
		return "OK";
	}
}

sub semcheck {
	# project id

	my ($project) = @_;

	my $lockfile = `echo "~/log/statsrun.lck"`;

	if(-e $lockfile) {
		$_ = `cat $lockfile`;
		chomp;
		return $_;
	} else {
		return;
	}
}

sub lastlog {
  # This function will either return or store the lastlog value for the specified project.
  #
  # lastlog("ogr","get") will return lastlog value.
  # lastlog("ogr","20001231-01") will set lastlog value to 31-Dec-2000 01:00 UTC

  my ($f_project, $f_action) = @_;

  if( $f_action =~ /get/i) {
    $_ = `cat ~/var/lastlog.$f_project`;
    chomp;
    return $_;
  } else {
    return `echo $f_action > ~/var/lastlog.$f_project`;
  }
}

sub lastday {
  # This function will either return or store the lastlog value for the specified project.
  #
  # lastday("ogr") will return lastday value for all ogr project_ids

  my ($f_project) = @_;

  if(!$statsconf::prids{$f_project}) {
    return 99999999;
  } else {
    my $qs_update = "select convert(char(8),max(DATE),112) from Daily_Summary where 2=1";
  
    my @pridlist = split /:/, $statsconf::prids{$f_project};
    for (my $i = 0; $i < @pridlist; $i++) {
      my $project_id = int $pridlist[$i];
      $qs_update ="$qs_update or PROJECT_ID = $project_id";
    }
    open TMP, ">/tmp/sqsh.tmp.$f_project";
    print TMP "$qs_update\ngo";
    close TMP;
    my $lastdaynewval = `sqsh -S$statsconf::sqlserver -U$statsconf::sqllogin -P$statsconf::sqlpasswd -w999 -w 999 -h -i /tmp/sqsh.tmp.$f_project`;
    $lastdaynewval =~ s/[^0123456789]//g;
    chomp $lastdaynewval;
    return $lastdaynewval;
  }
}

#
# $Id: stats.pm,v 1.8 2000/08/16 17:40:26 nugget Exp $
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

	open LOGFILE, ">>$logdir$project.log";
	print LOGFILE $ts," ",@par,"\n";
	close LOGFILE;

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
}

sub semflag {
	# project id
	# task at hand or NULL to signal clear

        my ($project, $task) = @_;

	my $lockfile = "$statsconf::logdir{$project}$project.lck";

	if($task) {
		if(semcheck($project) eq NULL) {
			# Apply lock
			`echo "$task" > $lockfile`;
			return "OK";

		} else {
			# Can't set the lock if it already exists.
			return semcheck($project);
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

	my $lockfile = "$statsconf::logdir{$project}$project.lck";

	if(-e $lockfile) {
		return `cat $lockfile`;
	} else {
		return NULL;
	}
}

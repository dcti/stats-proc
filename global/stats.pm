#
# $Id: stats.pm,v 1.5 2000/07/13 23:57:44 nugget Exp $
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

	my $ts = sprintf("[%d-%s-%d %02s:%02s]",$dd,$mm,$yy,$hh,$mi);

	open LOGFILE, ">>$logdir$project.log";
	print LOGFILE $ts," ",@par,"\n";
	close LOGFILE;

	# Display to stdout, of course.
	print $ts," ",@par,"\n";

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

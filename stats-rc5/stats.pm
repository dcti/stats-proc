# $Id: stats.pm,v 1.1 2003/09/11 02:04:01 decibel Exp $
# Stats global perl definitions/routines

package stats;

require IO::Socket;

$logtag = "statsbox-iii";
@projects = ("rc5");
%logdir = (
	"stats"	=> "/var/log/",
	"rc5"	=> "/usr/home/statproc/log/",
	"des"	=> "/usr/home/statproc/log/",
	"ogr"	=> "/usr/home/statproc/log/",
	"csc"	=> "/usr/home/statproc/log/",
);
%htdocs = (
	"stats"	=> "/htdocs/",
	"rc5"	=> "/htdocs/rc5/",
	"des"	=> "/htdocs/des/",
	"ogr"	=> "/htdocs/ogr/",
	"csc"	=> "/htdocs/csc/",
);
%incoming =  (
	"stats"	=> ".",
	"rc5"	=> "/usr/home/incoming/newlogs-rc5",
	"des"	=> "/usr/home/incoming/newlogs-des",
	"ogr"	=> "/usr/home/incoming/newlogs-ogr",
	"csc"	=> "/usr/home/incoming/newlogs-csc",
);

%projectdir = (
	"rc5"	=> "/usr/home/statproc/stats-rc5",
	"des"	=> "/usr/home/statproc/stats-des",
	"ogr"	=> "/usr/home/statproc/stats-ogr",
	"csc"	=> "/usr/home/statproc/stats-csc",
);

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
	my $logdir = $stats::logdir{$project};
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

	print $ts," ",@par,"\n";
	if ($dest & 8) {
                #pagers

		#open PAGER, "|mail \"-s$logtag/$project\" nugget-pager\@slacker.com";
		#print PAGER "@par\n";
                #close PAGER;

	}
	if ($dest & 1) {
		#dcti-logs
		if ($dest & 128) {
			$pass = "ircme";
		} else {
			$pass = "msgme";
		}
                DCTIeventsay("813", "$pass", "$project", @par);

	}
	if ($dest & 2) {
		#dcti
		if ($dest & 128) {
			$pass = "ircme";
		} else {
			$pass = "msgme";
		}
		DCTIeventsay("814", "$pass", "$project", @par);
	}
	if ($dest & 4) {
		#distributed
		if ($dest & 128) {
			$pass = "slacker";
		} else {
			$pass = "unclever";
		}
		DCTIeventsay("812", "$pass", "$project", @par);

	}
}

sub DCTIeventsay {
	# 0 project
	# 1 port
	# 2 password
	# 3 message

#	my $hub = "localhost";
	my $hub = "ircmonitor.distributed.net";
	
	my $port = shift;
	my $password = shift;
	my $project = shift;
	my $message = shift;

	local $SIG{ALRM} = sub { die "timeout" };

	eval {
		alarm 1;
		my $iaddr = gethostbyname( $hub ); 
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
			print "Connect to $hub timed out\n";
			$@ = "";
		} else {
			alarm 0;
			die;
		}
	}
}
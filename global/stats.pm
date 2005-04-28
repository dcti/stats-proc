#
# $Id: stats.pm,v 1.37 2005/04/28 20:01:03 decibel Exp $
#
# Stats global perl definitions/routines
#
# This should be world-readible from the production directory
# and symlinked someplace like /usr/lib/perl5 where it'll
# get caught in the perl include path.
#

package stats;

require IO::Socket;
require statsconf;
use DBI;
#use Data::Dumper;

BEGIN {
    # Connect to database(s)
    # Note we can't call debug in BEGIN
    print "stats::BEGIN connect to stats database $statsconf::database\n" if ($statsconf::debug >= 7); 
    if (not ($dbh = DBI->connect("DBI:Pg:dbname=$statsconf::database", $statsconf::sqllogin)) ) {
        stats::log($project,131,"Unable to connect to database '$statsconf::database' using login '$statsconf::sqllogin'!");
        die;
    }

    $dbh->{HandleError} = sub {
        stats::log($project,131,"Database error connecting to $statsconf::logdatabase: $_[0], $_[1]");
        die;
    };

    if ($statsconf::logdb) {
        print "stats::BEGIN connect to log database $statsconf::logdatabase\n" if ($statsconf::debug >= 7); 
        if (not ($logdbh = DBI->connect("DBI:Pg:dbname=$statsconf::logdatabase", $statsconf::sqllogin)) ) {
            stats::log($project,131,"Unable to connect to database '$statsconf::logdatabase' using login '$statsconf::sqllogin'!");
            die;
        }

        $logdbh->{HandleError} = sub {
            stats::log($project,131,"Database error connecting to $statsconf::logdatabase: $_[0], $_[1]");
            die;
        };
    }
}

sub debug ($$) {
    my ($level, $s) = @_;
    if ($statsconf::debug >= $level) {
        print $s;
    }
}

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

    debug(7,"stats::log logdir: $logdir\n");
    debug(7,"stats::log project: $project\n");
	if (open LOGFILE, ">>$logdir/$project.log") {
		print LOGFILE $ts," ",@par,"\n";
		close LOGFILE;
	} else {
		print "Unable to open [$logdir/$project.log]!\n";
		print STDERR "Unable to open [$logdir/$project.log]!\n";
	}

	if ($dest & 64) {
		print STDERR $ts," $project: ",@par,"\n";
	} else {
		print $ts," $project: ",@par,"\n";
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

		open PAGER, "|mail \"-s$statsconf::logtag/$project\" decibel-pager\@decibel.org";
		print PAGER "@par\n";
                close PAGER;

	}
}

sub DCTIeventsay {
	my $port = shift;
	my $password = shift;
	my $project = shift;
	my $message = shift;

        debug (6,"DCTIeventsay: port=$port, password=$password, project=$project, message=$message\n");
	
	local $SIG{ALRM} = sub { die "timeout" };

	eval {
		alarm 5;
		my $iaddr = gethostbyname( $statsconf::dctievent ); 
		my $proto = getprotobyname('tcp') || die "getproto: $!\n";
		my $paddr = Socket::sockaddr_in($port, $iaddr);
		socket(S, &Socket::PF_INET, &Socket::SOCK_STREAM, $proto) || die "socket: $!";
		if(connect(S, $paddr)) {
			print S "$password: ($statsconf::logtag/$project) $message\n";
			debug (9,"DCTIeventsay: $paddr $password: ($statsconf::logtag/$project) $message\n");
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

	if($task) {
	    if(semcheck($project)) {
		# Can't set the lock if it already exists.
			return semcheck($project);
		} else {
			# Apply lock
			`echo "$task" > $statsconf::lockfile`;
			return "OK";
		}
	} else {
		# Clear lock
		unlink $statsconf::lockfile;
		return "OK";
	}
}

sub semcheck {
	# project id

	my ($project) = @_;

	$statsconf::lockfile or die 'lockfile undefined';
	$statsconf::lockfile ne '' or die 'lockfile undefined (empty)';

	if(-e $statsconf::lockfile) {
        debug (2,"lockfile: $statsconf::lockfile exists\n");
		$_ = `cat $statsconf::lockfile`;
		chomp;
		return $_;
	} else {
        debug (2,"lockfile: $statsconf::lockfile does not exist\n");
		return;
	}
}

sub lastlog ($) {
    # This function will either return or store the lastlog value for the specified project.
    #
    # lastlog("ogr","get") will return lastlog value.
    # lastlog("ogr","20001231-01") will set lastlog value to 31-Dec-2000 01:00 UTC

    my ($f_project_type) = @_;
    my @result;

    my $stmt = $stats::dbh->prepare("SELECT to_char(max(log_timestamp), 'YYYYMMDD-HH24') FROM Projects p, Log_Info l WHERE l.project_id = p.project_id AND lower(p.project_type)=lower(?)");
    $stmt->execute($f_project_type);
    if (! (@result = $stmt->fetchrow_array) ) {
        stats::log($project,131,'Unable to retrieve lastlog information from database!');
        die;
    }

    return $result[0];
}

sub lastday {
    # This function will either return or store the lastlog value for the specified project.
    #
    # lastday("ogr") will return lastday value for all ogr project_ids

    my ($f_project_type) = @_;
    my @result;

    my $stmt = $stats::dbh->prepare("SELECT to_char(max(date), 'YYYYMMDD') FROM projects p, daily_summary d WHERE d.project_id = p.project_id AND lower(p.project_type)=lower(?)");
    $stmt->execute($f_project_type);
    if (! (@result = $stmt->fetchrow_array ) ) {
        stats::log($project,131,'Unable to retrieve lastday information from database!');
        die;
    }

    if(defined($result[0])) {
        return $result[0];
    } else {
        return "";
    }
}

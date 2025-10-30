#
# $Id: stats.pm,v 1.42 2010/10/06 04:54:30 jlawson Exp $
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
        print "Unable to connect to database '$statsconf::database' using login '$statsconf::sqllogin'!";
        die;
    }

    $dbh->{HandleError} = sub {
        stats::log($project,131,"Database error connecting to $statsconf::logdatabase: $_[0], $_[1]");
        die;
    };

    $statsconf::logdb = 0 if ! defined $statsconf::logdb;
    print ( "CONFIG: " . ($statsconf::logdb ? "" : "don't ") . "log to the log database\n" ) if ($statsconf::debug >= 1);

    if ($statsconf::logdb) {
        print "stats::BEGIN connect to log database $statsconf::logdatabase\n" if ($statsconf::debug >= 7); 
        if (not ($logdbh = DBI->connect("DBI:Pg:dbname=$statsconf::logdatabase", $statsconf::sqllogin)) ) {
            print "Unable to connect to database '$statsconf::logdatabase' using login '$statsconf::sqllogin'!";
            die;
        }

        $logdbh->{HandleError} = sub {
            stats::log($project,131,"Database error connecting to $statsconf::logdatabase: $_[0], $_[1]");
            die;
        };
    }

    print "stats::BEGIN done\n" if ($statsconf::debug >= 7); 
}

sub debug ($$) {
    my ($level, $s) = @_;
    if ($statsconf::debug >= $level) {
        print $s;
    }
}

sub log ($$$) {
    my ($project, $dest, $message) = @_;
    # Log activity
    #
    # Accepts:
	#   Project ID
    #   Log Destination
    #   Message
	#
	# dest:	  0 - file (always on)
	#	  1 - #dcti-logs
	#	  2 - #dcti
	#	  4 - #distributed
	#	  8 - pagers
	#	 64 - Print to STDERR instead of STDOUT
	#	128 - High Priority

	my $logdir = $statsconf::logdir{$project};
	my $pass = "";

	my $dd = (localtime)[3];
	my $mm = (Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec)[(localtime)[4]];
	my $yy = (localtime)[5]+1900;
	my $hh = (localtime)[2];
	my $mi = (localtime)[1];
	my $sc = (localtime)[0];

	my $ts = sprintf("[%d-%s-%d %02s:%02s:%02s]",$dd,$mm,$yy,$hh,$mi,$sc);

    debug(9,"stats::log logdir: $logdir\n");
    debug(9,"stats::log project: $project\n");
	if (open LOGFILE, ">>$logdir/$project.log") {
		print LOGFILE $ts," ",$message,"\n";
		close LOGFILE;
	} else {
		print "Unable to open [$logdir/$project.log]!\n";
		print STDERR "Unable to open [$logdir/$project.log]!\n";
	}

	if ($dest & 64) {
		print STDERR $ts," $project: ",$message,"\n";
	} else {
		print $ts," $project: ",$message,"\n";
	}


	# Cycle through configured irc channels and send to any that qualify
	for (my $i = 0; $i < @statsconf::ircchannels; $i++) {
		my ($bitmask,$channel,$port,$msg,$notify) = split /:/, $statsconf::ircchannels[$i];
		my $pass = $msg;
		if($dest & 128) {
			$pass = $notify;
		}
		if($dest & $bitmask) {
			DCTIeventsay($port, "$pass", "$project", $message);
		}
	}

	# Special "pagers" section
	if ($dest & 8) {
        #pagers

        if ($statsconf::pagers ne '') {
            open PAGER, "|mail \"-s$statsconf::logtag/$project\" $statsconf::pagers";
            print PAGER "$message\n";
            close PAGER;
        }

	}
}

sub DCTIeventsay ($$$$) {
    my ($port, $password, $project, $message) = @_;

    debug (8,"DCTIeventsay: port=$port, password=$password, project=$project, message=$message\n");
	
	local $SIG{ALRM} = sub { die "timeout" };

	eval {
		alarm 30;
		my $iaddr = gethostbyname( $statsconf::dctievent ); 
		my $proto = getprotobyname('tcp') || die "getproto: $!\n";
		my $paddr = Socket::sockaddr_in($port, $iaddr);
		socket(S, &Socket::PF_INET, &Socket::SOCK_STREAM, $proto) || die "socket: $!";
		if(connect(S, $paddr)) {
			print S "$password: ($statsconf::logtag/$project) $message\n";
			debug (9,"DCTIeventsay: $paddr $password: ($statsconf::logtag/$project) $message\n");
			close S;	
		} else {
			print "Could not reach $iaddr";
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
			print "Send to $statsconf::dctievent failed - $@\n";
			print STDERR "Send t to $statsconf::dctievent failed - $@ trying to report ($statsconf::logtag/$project) $message\n";
			#die;
		}
	}
}

sub semflag {
    my ($process, $task) = @_;
    # Set a lockfile
    # Accepts:
	#   Process name (hourly, log_import, etc)
	#   task at hand or NULL to signal clear
    #
    # Returns:
    #   Contents of lockfile if it exists, or undef if it doesn't


	if($task) {
	    if(semcheck($process)) {
		# Can't set the lock if it already exists.
			return semcheck($process);
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

sub semcheck ($) {
	my ($process) = @_;
    # Check to see if a lockfile exists
    # Accepts:
	#   Process name (hourly, log_import, etc)
    #
    # Returns:
    #   Contents of lockfile if it exists, or undef if it doesn't

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

#
# $Id: statsconf.pm,v 1.1 2003/09/11 02:04:01 decibel Exp $
#
# Stats global configuration
#

package statsconf;

$logtag = "statsbox-iii";
#@projects = ("ogr","rc5");
@projects = ("ogr");
%prids = (
        "rc5"   => "5",
        "ogr"   => "24:25",
);
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

#%logsource = (
#	"rc5"	=> "blower:/home/incoming/newlogs-rc5/",
#	"des"	=> "blower:/home/statproc/newlogs-des/",
#	"ogr"	=> "blower:/home/statproc/newlogs-ogr/",
#	"csc"	=> "blower:/home/statproc/newlogs-csc/",
#);

%logsource = (
	"rc5"	=> "master:/home/master/logs/",
	"des"	=> "master:/home/master/logs/",
	"ogr"	=> "master:/home/master/logs/",
	"csc"	=> "master:/home/master/logs/",
);

%prefilter = (
	"rc5"	=> "./logmod_rc5.pl",
	"des"	=> "",
	"ogr"	=> "./logmod_ogr.pl",
	"csc"	=> "",
);

# the $dctievent variable holds the hostname of the irc repeater
#
# populate @ircchannels with a list of each valid channel and its
# parameters.
#
#   bitmask:channel name:tcp port:normal password:loud password
#
# log messages will be &'d agains the bitmask to determine if the log
# will be sent to the channel.  loud password will be used if log
# (level & 128)

$dctievent = "moo.distributed.net";
@ircchannels = (
        "1:#dcti-logs:813:cmd:pass",
        "2:#dcti:814:cmd:pass",
        "4:#distributed:812:cmd:pass",
);

$sqllogin = "statproc";
$sqlpasswd = "pass#";
$sqlserver = "BLOWER";


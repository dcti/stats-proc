#!/usr/bin/perl -Tw
#
# $Id: logmod_ogr.pl,v 1.1 2000/02/21 23:06:08 nugget Exp $
#

use strict;

while(<>) {
  $_ =~ s/\/\d+-[^,]+//;
  print "$_";
}

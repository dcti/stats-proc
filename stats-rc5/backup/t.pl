#!/usr/bin/perl

my $dayrows = `sqsh -h -i dy_chcekday.sql`;

print "$dayrows";


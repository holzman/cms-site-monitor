#!/usr/bin/perl

use strict;
use FindBin qw($RealBin); ( my $root = $RealBin) =~ s/\/cgi-bin\/tier3\/mon//; my ($hpath) = '/htdocs/tier3/mon';
use lib $RealBin;
require 'subroutines.pl';


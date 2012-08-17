#!/usr/bin/perl

use strict;

use Fcntl qw( :DEFAULT :flock );

my %tat = (ab => 'tt');

my $bat = 99;
print qq( \$(please swing the ${bat}) )."\n";

1;


#!/usr/bin/perl

use strict;

use FindBin qw($RealBin);

use lib $RealBin;

require 'subroutines.pl';

print "Content-type:text/html\r\n\r\n";

my ($tmod,$dtim) = ( $ENV{QUERY_STRING_UNESCAPED} =~ /^([a-z]+)?_?(\d+)?$/ );

my $mode = ${{ qstat => 0, condorq => 1 }}{$tmod} // 0; $dtim //= (time - 300); my $ltim = ( $dtim - ($dtim % 300));

print '<h2>The '.(( qw( TORQUE Condor))[$mode]).' Queue WayBack Machine</h2>'."\n".'<p>'."\n";

print &QUEUE_TABLE($mode,$ltim);

print '<br>'."\n".'View <a href="wayback.shtml?'.(( qw( condorq qstat))[$mode]).'_'.($ltim).'" class="mon_default" target="WAYBACK">'.(( qw( Condor TORQUE))[$mode]).'</a> Queue'."\n".'<br>'."\n";

1;


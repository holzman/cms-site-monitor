#!/usr/bin/perl

use strict;

use FindBin qw($RealBin);

use lib $RealBin;

require 'subroutines.pl';

print "Content-type:text/html\r\n\r\n" if (exists $ENV{HTTP_HOST});

my ($alrt) = ( $ENV{QUERY_STRING_UNESCAPED} =~ /^(\w+)$/ );

my (@alrt) = &LOAD_ALERT( $alrt, qw( alert title long active ));

my ($summ) = &SUMM_ALERT() // {}; 

print '<h2>Alert Summary'.((defined $alrt) && !(!@alrt) && ' - '.$alrt[0][1]).'</h2>'."\n".'<p>'."\n";

print '<DIV id="alert_data_anchor" style="z-index:0; display:block; position:static; height:auto; width:826px; margin:0px 0px; padding:0px; text-align:center; overflow:hidden;">'."\n";
print "\t".'<table class="mon_default" style="width:826px; height:auto;">'."\n";
my ($j) = 0; for (@alrt) { my ($stmp,$alvl) = @{ $$summ{$$_[0]} // [] };
	my ($mode) = ($$_[3]) ? ($$_[3] == 1) ? (defined $stmp) ? do { $stmp = ( &DATE_FORMAT($stmp,1,q(%A, %Y-%m-%d %R UTC))); ($alvl == 0) ? 3 : 2 } : 1 : 0 : -1;
	print "\t\t".'<tr class="mon_default" style="color:black; background-color:#FFFFFF;">'."\n";
	print "\t\t\t".'<td class="mon_default" style="width:210px; height:16px; color:black; background-color:#20B2AA;">'.($$_[1]).'</td>'."\n";
	print "\t\t\t".'<td class="mon_inset" rowspan="2" style="width:566px; height:auto; text-align:justify; color:black; background-color:#' .
		(( qw( E9FBFA B3F3F0 ))[($j++)%2]).';">'.($$_[2]).'</td>'."\n";
	print "\t\t".'</tr>'."\n";
	print "\t\t".'<tr class="mon_default" style="color:black; background-color:#FFFFFF;">'."\n";
	print "\t\t\t".'<td class="mon_default" style="width:210px; height:auto; color:black; background-color:'.(( q(#FFFFFF), qw( orange red green ), q(#FFFFFF))[$mode]).';">' .
		((q(Alert has NULL Status), q(Test Status: UNKNOWN<br>No Result for 24 Hours),
			q(Test Status: FAILED<br>).($stmp), q(Test Status: PASSED<br>).($stmp), q(Alert is Disabled))[$mode]).'</td>'."\n";
	print "\t\t".'</tr>'."\n"; }
print "\t\t".'<tr class="mon_default" style="color:white; background-color:#E62E2E;">'."\n" .
	"\t\t\t".'<td class="mon_default" style="width:810px; height:16px;">No '.((defined $alrt)?'Matching Alert':'Alerts').' Located</td>'."\n" .
	"\t\t".'</tr>'."\n" unless (@alrt);
print "\t".'</table>'."\n";
print '</DIV>'."\n";

print '<br>'."\n";

print 'View <a href="alert.shtml" class="mon_default">All</a> Alerts'."\n".'<br>'."\n" if (defined $alrt);

1;


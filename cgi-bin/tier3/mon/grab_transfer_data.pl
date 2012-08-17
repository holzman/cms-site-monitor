#!/usr/bin/perl

# SOURCE, PRODUCTION_STATUS, LOAD_TEST_STATUS

# SOURCE, TIME, RATE, BYTES, FILES, EXPIRED, ERRORS

use strict;

use FindBin qw($RealBin);

use lib $RealBin;

require 'subroutines.pl';

use LWP::UserAgent ();
use HTTP::Request::Common ();

my ($brsr) = LWP::UserAgent->new();

( my $root = $RealBin) =~ s/\/cgi-bin\/tier3\/mon//; my ($opath) = '/OFFLINE/tier3/mon';

my ($lhour) = my ($time) = time; $lhour -= ($lhour % 3600);

my ($log) = "@ARGV" =~ /\blog\b/;

my (%transfer); for my $updn (1) { for my $prld (0,1) { my ($file); my ($response) = $brsr->request(HTTP::Request::Common::GET(
	'https://cmsweb.cern.ch/phedex/'.(( qw( prod debug ))[$prld]).'/Components::Links?' .
		'from_filter='.(( q(T3_US_TAMU), q(.*) )[$updn]).'&andor=and&to_filter='.(( q(.*), q(T3_US_TAMU) )[$updn])),
	$file = $root.$opath.'/DOWNLOAD/link_'.(( qw( to from ) )[$updn]).'_'.(( qw( prod load ) )[$prld]).'_data.txt' );
	unless ($response->is_success) { die $response->status_line; } open FHI, $file; outer: while (<FHI>) { next unless /^<tbody>/;
		inner: while (<FHI>) { last outer if /^<\/tbody>/; chomp; do { s/&[\w#]*;//g; my ($code) = s/^<div [^>]*background-color:(\w+);'>//i ?
			${{ q(green) => 0, q(red) => 1, q(orange) => 2, q(purple) => 3, q(white) => 4, q(black) => 5 }}{(lc $1)} : next;
			( m/^<div [^>]*><p><b>(\w+)\s+(\w+)/i )[$updn] eq q(T3_US_TAMU) ? $transfer{($2,$1)[$updn]}[$updn][$prld]{link} = $code : next; }
		for ( m/<td[^>]*>(.*?)<\/td>/g ); }} close FHI; }}

for my $updn (1) { for my $prld (0,1) { for my $mode (0..3) { my ($file); my ($response) = $brsr->request(HTTP::Request::Common::GET(
	'https://cmsweb.cern.ch/phedex/'.(( qw( prod debug ))[$prld]).'/Activity::Rate?span='.(( qw( h d w m ))[$mode]).'&errors=on&' .
		'fromfilter='.(( q(T3_US_TAMU), q(.*) )[$updn]).'&andor=and&tofilter='.(( q(.*), q(T3_US_TAMU) )[$updn])),
	$file = $root.$opath.'/DOWNLOAD/rate_'.(( qw( to from ) )[$updn]).'_'.(( qw( prod load ) )[$prld]).'_'.(( qw( hour day week month ))[$mode]).'_data.txt' );
	unless ($response->is_success) { die $response->status_line; } open FHI, $file; outer: while (<FHI>) { next unless /^<tbody>/;
		inner: while (<FHI>) { last outer if /^<\/tbody>/; chomp; do { $transfer{( shift @$_ )}[$updn][$prld]{rate}[$mode] = $_ } for map {[
			$$_[(0,2)[$updn]], $lhour, ( map { s/\/s$//; &DATA_FORMAT_HUMAN_EXP($_||q(0)) } @$_[5,4] ), ( map { int } @$_[3,7,6] ) ]}
		grep { &SUM(@$_[3..7]) } grep { $$_[(2,0)[$updn]] eq 'T3_US_TAMU' } [ grep { s/&[\w#]*;//g; s/<[^>]*>//g; 1 } m/<td[^>]*>(.*?)<\/td>/g ]; }} close FHI; }}}

open FHO, '>'.$root.'/htdocs/tier3/mon/SSI/TABLES/transfer_data.ssi'; select FHO;

my ($i) = 0; my ($trct) = 0+ keys %transfer; my ($rtxt,$ltxt,$sums);
for my $node (sort keys %transfer) { for my $updn (1) { my ($link) = $transfer{$node}[$updn] // []; $ltxt .=
	"\t\t\t".'<tr class="mon_default">'."\n" .
	"\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px; color:black; background-color:' .
		(( qw( green red orange purple white black ))[ $$link[0]{link} // 5 ]).';">' .
		(( q(Valid), q(Agent Down), q(Excluded), q(Deactivated), q(No Link), q(Null) )[ $$link[0]{link} // 5 ]).'</td>'."\n" .
	"\t\t\t\t".'<td class="mon_default" style="width:166px; height:16px; color:black; background-color:#'.(( qw( E9FBFA B3F3F0 ))[$i%2]).';">'.( $node || '-' ).'</td>'."\n" .
	"\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px; color:black; background-color:' .
		(( qw( green red orange purple white black ))[ $$link[1]{link} // 5 ]).';">' .
		(( q(Valid), q(Agent Down), q(Excluded), q(Deactivated), q(No Link), q(Null) )[ $$link[1]{link} // 5 ]).'</td>'."\n" .
	(($i == 0) && "\t\t\t\t".'<td class="mon_default" style="width:450px; height:'.(26*$trct-10).'px; color:black; background-color:white;" colspan="5" rowspan="'.($trct+1).'"></td>'."\n") .
	"\t\t\t".'</tr>'."\n";
	for my $prld (0,1) { for my $mode (0..3) { $$rtxt[$prld][$mode] .=
		"\t\t\t".'<tr class="mon_default">'."\n" . ( join '', map {
		"\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px; color:black; background-color:#' .
			(( qw( E9FBFA B3F3F0 ))[$i%2]).'">'.$_.'</td>'."\n" } $$link[$prld]{rate}[$mode] ? do { my @vals = @{ $$link[$prld]{rate}[$mode]}[1..5];
			$$sums[$prld][$mode][$_] += &DATA_FORMAT_EXP_BYTES($vals[$_]) for (0,1); $$sums[$prld][$mode][$_] += $vals[$_] for (2..4);
			( &DATA_FORMAT_EXP_HUMAN($vals[0],1).'/s', &DATA_FORMAT_EXP_HUMAN($vals[1],1), ( map { &COMMA($_) } @vals[2..4] )) } : qw( - - - - - )) .
		"\t\t\t".'</tr>'."\n"; }}}} continue { $i++; }

print '<DIV id="transfer_data_anchor" style="z-index:0; display:block; position:relative; top:0px; left:0px; height:'.(26*($trct+3)+6).'px; width:826px; margin:0px 0px; padding:0px; text-align:center; overflow:hidden;">'."\n";

for my $mode (0..3) { for my $prld (0,1) {
	print "\t".'<DIV id="transfer_data_'.( qw( prod load )[$prld]).'_'.( qw( hour day week month )[$mode]).'" style="z-index:'.((($mode==1)&&($prld==0))?10:-10) .
		'; display:block; position:absolute; top:55px; left:363px; height:'.(26*($trct+1)).'px; width:460px; margin:0px 0px; padding:0px; text-align:center; overflow:hidden;">'."\n";
	print "\t\t".'<table class="mon_inner" style="width:460px; height:'.(26*($trct+1)).'px;">'."\n";
	print $$rtxt[$prld][$mode];
	print "\t\t\t".'<tr class="mon_default" style="color:black; background-color:#20B2AA;">'."\n";
	print "\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px;">' .
		((defined $$sums[$prld][$mode][0]) ? ( &DATA_FORMAT_BYTES_HUMAN($$sums[$prld][$mode][0],1)).'/s' : q(-)).'</td>'."\n";
	print "\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px;">' .
		((defined $$sums[$prld][$mode][1]) ? ( &DATA_FORMAT_BYTES_HUMAN($$sums[$prld][$mode][1],1)) : q(-)).'</td>'."\n";
	print "\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px;">'.( &COMMA($$sums[$prld][$mode][2])//q(-)).'</td>'."\n";
	print "\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px;">'.( &COMMA($$sums[$prld][$mode][3])//q(-)).'</td>'."\n";
	print "\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px;">'.( &COMMA($$sums[$prld][$mode][4])//q(-)).'</td>'."\n";
	print "\t\t\t".'</tr>'."\n";
	print "\t\t".'</table>'."\n";
	print "\t".'</DIV>'."\n"; }}

print "\t".'<DIV style="z-index:0; display:block; position:static; height:'.(26*($trct+3)+6).'px; width:826px; margin:0px 0px; padding:0px; text-align:center; overflow:hidden;">'."\n";
print "\t\t".'<table class="mon_default" style="width:826px; height:'.(26*($trct+3)+6).'px;">'."\n";
print <<EndHTML;
			<tr class="mon_default" style="color:black; background-color:#FFFFFF;">
				<td class="mon_default" id="transfer_data_mode_select_prod" style="width:82px; height:16px; color:black; background-color:#3BB9FF; cursor:pointer;" onClick="javascript:TransferDataModeSelect(0);" onMouseOver="javascript:this.style.backgroundColor=\'#3BB9FF\';" onMouseOut="javascript:if(TransferDataModeIndex!=0)this.style.backgroundColor=\'#FFFFFF\';">&darr; Production</td>
				<td class="mon_default" style="width:166px; height:16px;">PhEDEx Data Transfers</td>
				<td class="mon_default" id="transfer_data_mode_select_load" style="width:82px; height:16px; color:black; background-color:#FFFFFF; cursor:pointer;" onClick="javascript:TransferDataModeSelect(1);" onMouseOver="javascript:this.style.backgroundColor=\'#3BB9FF\';" onMouseOut="javascript:if(TransferDataModeIndex!=1)this.style.backgroundColor=\'#FFFFFF\';">Load Test &darr;</td>
				<td class="mon_default" style="width:82px; height:16px;">&larr; Select &rarr;</td>
				<td class="mon_default" id="transfer_data_span_select_hour" style="width:82px; height:16px; color:black; background-color:#FFFFFF; cursor:pointer;" onClick="javascript:TransferDataSpanSelect(0);" onMouseOver="javascript:this.style.backgroundColor=\'#3BB9FF\';" onMouseOut="javascript:if(TransferDataSpanIndex!=0)this.style.backgroundColor=\'#FFFFFF\';">Hour</td>
				<td class="mon_default" id="transfer_data_span_select_day" style="width:82px; height:16px; color:black; background-color:#3BB9FF; cursor:pointer;" onClick="javascript:TransferDataSpanSelect(1);" onMouseOver="javascript:this.style.backgroundColor=\'#3BB9FF\';" onMouseOut="javascript:if(TransferDataSpanIndex!=1)this.style.backgroundColor=\'#FFFFFF\';">Day</td>
				<td class="mon_default" id="transfer_data_span_select_week" style="width:82px; height:16px; color:black; background-color:#FFFFFF; cursor:pointer;" onClick="javascript:TransferDataSpanSelect(2);" onMouseOver="javascript:this.style.backgroundColor=\'#3BB9FF\';" onMouseOut="javascript:if(TransferDataSpanIndex!=2)this.style.backgroundColor=\'#FFFFFF\';">Week</td>
				<td class="mon_default" id="transfer_data_span_select_month" style="width:82px; height:16px; color:black; background-color:#FFFFFF; cursor:pointer;" onClick="javascript:TransferDataSpanSelect(3);" onMouseOver="javascript:this.style.backgroundColor=\'#3BB9FF\';" onMouseOut="javascript:if(TransferDataSpanIndex!=3)this.style.backgroundColor=\'#FFFFFF\';">Month</td>
			</tr>
			<tr class="mon_default" style="color:black; background-color:#20B2AA;">
				<td class="mon_default" style="width:82px; height:16px;">Link Status</td>
				<td class="mon_default" style="width:166px; height:16px;">Linked Node</td>
				<td class="mon_default" style="width:82px; height:16px;">Link Status</td>
				<td class="mon_default" style="width:82px; height:16px;">Rate</td>
				<td class="mon_default" style="width:82px; height:16px;">Bytes</td>
				<td class="mon_default" style="width:82px; height:16px;">Files</td>
				<td class="mon_default" style="width:82px; height:16px;">Expired</td>
				<td class="mon_default" style="width:82px; height:16px;">Errors</td>
			</tr>
${ltxt}
			<tr class="mon_default">
				<td class="mon_default" style="color:black; background-color:#20B2AA; width:350px; height:16px;" colspan="3">Totals</td>
			</tr>
		</table>
	</DIV>
</DIV>

EndHTML

open FHO, '>'.($root.$opath).'/PERSIST/transfer_rate_prod_hourly.dat'; print FHO q().($time)."\t".($$sums[0][0][0])."\n"; close FHO;

#exit unless $log; for (@rate) { open FHO, '>>'.$root.$opath.'/TABLES/RATE_DATA/'.( shift @$_ ).'.dat'; print FHO +( join "\t", @$_ )."\n"; close FHO; }

#open FHO, '>'.$root.$opath.'/TABLES/LINK_DATA/'.$lhour.'.dat'; print FHO +( join "\t", @$_ )."\n" for @transfer; close FHO;

=pod

https://cmsweb.cern.ch/phedex/prod/Activity::Routing?tofilter=T3_US_TAMU&fromfilter=.*&priority=any&showinvalid=on&blockfilter=.*&.submit=Update#

https://cmsweb.cern.ch/phedex/prod/Activity::TransferDetails?tofilter=T3_US_TAMU&andor=and&fromfilter=.*

https://cmsweb.cern.ch/phedex/prod/Activity::ErrorInfo?tofilter=T3_US_TAMU&fromfilter=.*&report_code=.*&xfer_code=.*&to_pfn=.*&from_pfn=.*&log_detail=.*&log_validate=.*&.submit=Update#

https://cmsweb.cern.ch/phedex/prod/Activity::Rate?span=d&errors=on&fromfilter=.*&andor=and&tofilter=T3_US_TAMU

=cut


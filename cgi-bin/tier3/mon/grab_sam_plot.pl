#!/usr/bin/perl

use strict;

use FindBin qw($RealBin);

use lib $RealBin;

require 'subroutines.pl';

use LWP::UserAgent ();
use HTTP::Request::Common ();

my ($brsr) = LWP::UserAgent->new();

( my $root = $RealBin) =~ s/\/cgi-bin\/tier3\/mon//; my ($hpath) = '/htdocs/tier3/mon'; my ($opath) = '/OFFLINE/tier3/mon';

local $_ = "@ARGV"; my ($log) = m/\blog\b/i;

my ($time) = time;

do { my ($mode,$curl) = @$_; ( $brsr->request( HTTP::Request::Common::GET($curl),
	$root.$opath.'/DOWNLOAD/sam_status_'.($mode).'_data.txt' ))->is_success() || next; }
for map { my ($mode,$hrup,$dbak,$page,$pars) = @$_; my ($dtfr,$dtto) =
	map {( &DATE_FORMAT((($_)-($dbak*24*60*60)),1,q(%Y-%m-%dT%H%%3A%M%%3A%SZ)), &DATE_FORMAT($_,1,q(%Y-%m-%dT%H%%3A%M%%3A%SZ)))}
	map {( $_ + ( map {( $_ && (($hrup*60*60)-($_)))} (($_)%($hrup*60*60)))[0])} ($time - 300);
	[ $mode, q(http://dashb-cms-sum.cern.ch/dashboard/request.py/).($page).q(?).($pars).q(&start_time=).($dtfr).q(&end_time=).($dtto) ]} (
		[ q(hourly), 1, 2, q(getTestResults),
			q(profile_name=CMS_CRITICAL&hostname=hurr.tamu.edu) .
			q(&flavours=OSG-CE%2COSG-SRMv2&metrics=All&time_range=individual) ],
		[ q(daily), 24, 45, q(getAvailabilityResults),
			q(profile_name=CMS_CRITICAL&group_name=T3_US_TAMU&view=siteavl&plot_type=quality) .
			q(&flavour=null&granularity=daily&time_range=individual) ]);

my (@tsts) = (
	[ q(org.cms.SRM-AllCMS), q(OSG-SRMv2) ], [ q(org.cms.SRM-GetPFNFromTFC), q(OSG-SRMv2) ], [ q(org.cms.SRM-VODel), q(OSG-SRMv2) ],
	[ q(org.cms.SRM-VOGet), q(OSG-SRMv2) ], [ q(org.cms.SRM-VOGetTURLs), q(OSG-SRMv2) ], [ q(org.cms.SRM-VOLs), q(OSG-SRMv2) ],
	[ q(org.cms.SRM-VOLsDir), q(OSG-SRMv2) ], [ q(org.cms.SRM-VOPut), q(OSG-SRMv2) ], [ q(org.cms.WN-analysis), q(OSG-CE) ],
	[ q(org.cms.WN-basic), q(OSG-CE) ], [ q(org.cms.WN-frontier), q(OSG-CE) ], [ q(org.cms.WN-mc), q(OSG-CE) ],
	[ q(org.cms.WN-squid), q(OSG-CE) ], [ q(org.sam.CE-JobSubmit), q(OSG-CE) ]);
my ($hgt0,$hgt1,$hgt2,$hgt3) = map { ($_), ($_+38), ($_+74), ($_+142) } (17*(0+@tsts)-1);

open FHO, '>'.$root.'/htdocs/tier3/mon/SSI/TABLES/sam_plot.ssi'; select FHO;

print <<EndHTML;

<DIV id="sam_plot_anchor" style="z-index:0; display:block; position:relative; top:0px; left:0px; height:${hgt3}px; width:826px; margin:0px 0px; padding:0px; text-align:center; overflow:hidden;">
	<table class="mon_default" style="width:826px; height:${hgt3}px;">
		<tr class="mon_default">
			<td class="mon_default" colspan="2" style="width:810px; height:16px;">Service Availability Monitoring (SAM) Tests</td>
		</tr>
		<tr class="mon_default">
			<td class="mon_default" style="width:400px; height:${hgt2}px;">
				<DIV id="sam_plot_hourly_anchor" style="z-index:0; display:block; position:static; height:${hgt1}px; width:363px; margin:18px 19px 18px 18px; padding:0px; text-align:center; overflow:hidden;">
					<table class="mon_thumb" style="width:363px; height:${hgt1}px;">
						<tr class="mon_thumb">
							<td class="mon_thumb" colspan="49" style="padding:2px; width:355px; height:12px;">Itemized SAM Test Results (Last 48 Hours)</td>
						</tr>
EndHTML
my (@scor); for my $mode ( qw(hourly)) { open FHI, ($root.$opath).'/DOWNLOAD/sam_status_'.($mode).'_data.txt'; my ($dtfr); my (%qlty) =
	map { /^"(org\.[^"]*)", \[(.*)]$/ ? ( qq($1) => [ map { ((@$_ >= 2) && ($$_[0] =~ /^\d{10,}$/) && ($$_[1] =~ /^"([A-Z]+)/)) ?
		[ 0+$$_[0], ${{ OK => 1, WARNING => 2, CRITICAL => 3, MISSING => 4, UNKNOWN => 5, REMOVED => 6 }}{$1} ] : () }
		map {[ split /\,\s+/ ]} ( $2 =~ m/\[(.*?)](?=$|, )/g ) ]) : () } map { m/\[("org\..*?]])]/g }
	grep { $dtfr = Time::Local::timegm($6,$5,$4,$3,($2-1),$1) if /start_time=(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z/; 1 } (<FHI>); close FHI;
	my ($i) = 0; do { my ($mtrc,$flvr) = @$_;
		print "\t\t\t\t\t\t".'<tr class="mon_thumb">'."\n";
		print "\t\t\t\t\t\t\t".'<td class="mon_thumb" style="padding:2px; width:67px; height:12px; color:black; background-color:#FFFFFF;"><DIV style="z-index:0; display:block; position:static; height:12px; width:67px; margin:0px 0px; padding:0px; text-align:center; overflow:hidden; white-space:nowrap; text-overflow:ellipsis; color:black; background-color:#FFFFFF;">'.(($mtrc =~ /^org\.[a-z]+\.(.*)$/)?qq($1):$mtrc).'</DIV></td>'."\n";
		for my $j (0..47) { ( shift @{ $qlty{$mtrc}} ) while ((0+@{ $qlty{$mtrc} //= []}) && ($qlty{$mtrc}[0][0] < ($dtfr + $j*60*60)));
			my ($stmp,$code) = ((0+@{ $qlty{$mtrc}}) && ($qlty{$mtrc}[0][0] < ($dtfr + 60*60*(1+$j)))) ? @{ shift @{ $qlty{$mtrc}}} : ();
			my ($colr) = ( undef, qw( green orange red sienna gray black ))[0+$code];
			push @{ $scor[$j] ||= [] }, grep {(defined)} ( undef, 1, 0.5, 0 )[0+$code];
			print "\t\t\t\t\t\t\t".'<td class="mon_thumb" style="width:5px; height:16px; color:black; background-color:'.(($colr) || q(#FFFFFF)).';'.(($colr)?' cursor:pointer;" onClick="javascript:window.open(\'http://dashb-cms-sum.cern.ch/dashboard/request.py/getMetricResultDetails?hostName=hurr.tamu.edu&amp;flavour='.($flvr).'&amp;metric='.($mtrc).'&amp;timeStamp='.( &DATE_FORMAT($stmp,1,q(%Y-%m-%dT%H%%3A%M%%3A%SZ))).'\',\'NEW\');" onMouseOver="javascript:SAMPlotOverlayShow(this,'.(($i<=7)?($hgt0+14):70).','.(( sort {$a<=>$b} (99,3+6*$j,188))[1]).',\''.($flvr).' : '.($mtrc).'<br>Test Status : '.(( undef, qw( PASSED WARNING FAILED MISSING UNKNOWN REMOVED ))[($code)]).'<br>'.( &DATE_FORMAT(($dtfr+$j*60*60),1,q(%A, %Y-%m-%d %R UTC))).'<br>Click for Detailed Test Log\');" onMouseOut="javascript:SAMPlotOverlayHide(this,\''.($colr).'\');"':'"').'></td>'."\n"; }
		print "\t\t\t\t\t\t".'</tr>'."\n"; $i++ } for (@tsts);
		print "\t\t\t\t\t\t".'<tr class="mon_thumb">'."\n";
		print "\t\t\t\t\t\t\t".'<td class="mon_thumb" style="padding:2px; width:67px; height:12px; color:black; background-color:#FFFFFF;">&uarr; SAM Metric</td>'."\n";
		print "\t\t\t\t\t\t\t".'<td class="mon_thumb" colspan="48" style="padding:2px; width:283px; height:12px;">'."\n";
		print "\t\t\t\t\t\t\t\t".'<DIV style="float:left; clear:none; width:50%; height:12px; margin:0px; padding:0px; text-align:left;">&larr; '.( &DATE_FORMAT($dtfr,1,q(%Y-%m-%d %R UTC))).'</DIV>'."\n";
		print "\t\t\t\t\t\t\t\t".'<DIV style="float:left; clear:none; width:50%; height:12px; margin:0px; padding:0px; text-align:right;">'.( &DATE_FORMAT(($dtfr+48*60*60),1,q(%Y-%m-%d %R UTC))).' &rarr;</DIV>'."\n";
		print "\t\t\t\t\t\t\t".'</td>'."\n";
		print "\t\t\t\t\t\t".'</tr>'."\n"; }
print <<EndHTML;
					</table>
				</DIV>
			</td>
			<td class="mon_default" style="width:400px; height:${hgt2}px;">
				<DIV id="sam_plot_daily_anchor" style="z-index:0; display:block; position:static; height:${hgt1}px; width:363px; margin:18px 18px 18px 19px; padding:0px; text-align:center; overflow:hidden;">
					<table class="mon_thumb" style="width:363px; height:${hgt1}px;">
						<tr class="mon_thumb">
							<td class="mon_thumb" colspan="45" style="padding:2px; width:355px; height:12px;">SAM Test Site Quality Summary (Last 45 Days)</td>
						</tr>
EndHTML
		print "\t\t\t\t\t\t".'<tr class="mon_thumb">'."\n";
my (@dwms); for my $mode ( qw(daily)) { open FHI, ($root.$opath).'/DOWNLOAD/sam_status_'.($mode).'_data.txt'; my ($dtfr); my (@qlty) =
	map {[ $_, &COLOR_FORMAT_RGB_HEX( &QUALITY_FORMAT_SCORE_RGB($_)) ]}
	map { ((@$_ == 3) && ($$_[1] =~ /^"(\d\.\d{2})"$/)) ? &ROUND(100*$1,0) : () }
	map {[ split /\,\s+/ ]} map { m/\[([^][]*)]/g } grep { $dtfr = Time::Local::timegm($6,$5,$4,$3,($2-1),$1) if
		/start_time=(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z/; 1 } (<FHI>); close FHI;
	@dwms = map { &ROUND($_,0) // undef } map { &AVG( map {($$_[0])} grep {(defined)} @qlty[((44-$_+(defined $qlty[44]))..(43+(defined $qlty[44])))]) // undef } (1,7,30);
	for my $i (0..44) { my ($qlty,$colr) = @{ $qlty[$i]||[]}; print "\t\t\t\t\t\t\t".'<td class="mon_thumb" style="width:7px; height:'.($hgt0).'px; color:black; background-color:'.(($colr) || q(#FFFFFF)).';'.(($colr)?' cursor:pointer;" onClick="javascript:window.open(\'http://dashb-cms-sum.cern.ch/dashboard/request.py/historicalsmryview-sum#view=test&amp;time%5B%5D=individual&amp;granularity%5B%5D=hourly&amp;profile=CMS_CRITICAL&amp;group=Tier3s&amp;site%5B%5D=T3_US_TAMU&amp;flavour%5B%5D=All+Service+Flavours&amp;metric%5B%5D=All+Metrics&amp;host%5B%5D=hurr.tamu.edu&amp;starttime='.( &DATE_FORMAT(($dtfr+$i*24*60*60),1,q(%Y-%m-%d+%H%%3A%M%%3A%S))).'&amp;endtime='.( &DATE_FORMAT(($dtfr+(24*60*60)*(1+$i)),1,q(%Y-%m-%d+%H%%3A%M%%3A%S))).'\',\'NEW\');" onMouseOver="javascript:SAMPlotOverlayShow(this,'.($hgt0+14).','.(( sort {$a<=>$b} (438,342+8*$i,599))[1]).',\'Daily Site Quality : '.($qlty).' &#37;<br>'.( &DATE_FORMAT(($dtfr+$i*24*60*60),1,q(%A, %Y-%m-%d %R UTC))).'<br>Click for Itemized SAM Test<br>Results Grouped by Hour\');" onMouseOut="javascript:SAMPlotOverlayHide(this,\''.($colr).'\');"':'"').'></td>'."\n"; }
		print "\t\t\t\t\t\t".'</tr>'."\n";
		print "\t\t\t\t\t\t".'<tr class="mon_thumb">'."\n";
		print "\t\t\t\t\t\t\t".'<td class="mon_thumb" colspan="45" style="padding:2px; width:355px; height:12px;">'."\n";
		print "\t\t\t\t\t\t\t\t".'<DIV style="float:left; clear:none; width:50%; height:12px; margin:0px; padding:0px; text-align:left;">&larr; '.( &DATE_FORMAT($dtfr,1,q(%Y-%m-%d %R UTC))).'</DIV>'."\n";
		print "\t\t\t\t\t\t\t\t".'<DIV style="float:left; clear:none; width:50%; height:12px; margin:0px; padding:0px; text-align:right;">'.( &DATE_FORMAT(($dtfr+45*24*60*60),1,q(%Y-%m-%d %R UTC))).' &rarr;</DIV>'."\n";
		print "\t\t\t\t\t\t\t".'</td>'."\n";
		print "\t\t\t\t\t\t".'</tr>'."\n"; }
print <<EndHTML;
					</table>
				</DIV>
			</td>
		</tr>
		<tr class="mon_default">
			<td colspan="2" class="mon_default" style="width:810px; height:16px; color:black; background-color:#FFFFFF; cursor:pointer;" onClick="javascript:TopUp.displayTopUp(document.getElementById('sam_plot_leader'));" onMouseOver="javascript:this.style.backgroundColor='#3BB9FF';" onMouseOut="javascript:this.style.backgroundColor='#FFFFFF';">
				<DIV style="float:left; clear:none; width:50%; height:16px; margin:0px; padding:0px; text-align:center;">&uarr; Click to Enlarge Plots</DIV>
				<DIV style="float:left; clear:none; width:50%; height:16px; margin:0px; padding:0px; text-align:center;">Plot Cells Link to Details &uarr;</DIV>
			</td>
		</tr>
	</table>
	<DIV id="sam_plot_overlay" style="z-index:10; display:none; position:absolute; top:0px; left:0px; height:48px; width:190px; margin:0px; padding:3px; border-width:2px; border-style:solid; border-color:#000000; color:#000000; background-color:#BBDDFF; text-align:center; white-space:nowrap; line-height:12px; font-size:10px; font-weight:500; font-family:Geneva,Helvetica,Verdana,sans-serif; font-variant:normal; font-style:normal; overflow:hidden;"></DIV>
</DIV>

EndHTML

close FHO;

do { &ALERT(( undef, qw( SAM_FAIL SAM_SKIP ))[$$_[0]],2,1,($$_[1]//())) } for (( map { my ($frac,$scor) = ( &SAFE_RATIO(0+(@$_),0+(@tsts)), &AVG(@$_));
	($frac < 0.1) ? () : ($scor < 0.8) ? [1,( &ROUND(100*$scor,0))] : ($frac < 0.5) ? () : [0] } ( reverse @scor )[0..( int (0.1*@scor))] ), [2] )[0];

open FHO, '>'.($root).'/htdocs/tier3/mon/SSI/TABLES/sam_percentage.ssi'; select FHO;

print <<EndHTML;

<DIV id="sam_percentage_anchor" style="z-index:0; display:block; position:static; height:84px; width:282px; margin:0px 272px; padding:0px; text-align:center; overflow:hidden;">
	<table class="mon_default" style="width:282px; height:84px;">
		<tr class="mon_default">
			<td class="mon_default" colspan="3" style="width:266px; height:16px;">Service Availability Percentage</td>
		</tr>
		<tr class="mon_default">
			<td class="mon_default" style="width:82px; height:16px; color:black; background-color:#20B2AA;">Day</td>
			<td class="mon_default" style="width:82px; height:16px; color:black; background-color:#20B2AA;">Week</td>
			<td class="mon_default" style="width:82px; height:16px; color:black; background-color:#20B2AA;">Month</td>
		</tr>
		<tr class="mon_default">
EndHTML

print "\t\t\t".'<td class="mon_default" style="width:82px; height:16px; color:black; background-color:' .
	((defined) ? ( &COLOR_FORMAT_RGB_HEX( &QUALITY_FORMAT_SCORE_RGB($_))) : q(#FFFFFF)).';">' .
	((defined) ? ($_).q( &#37;) : q(-)).'</td>'."\n" for (@dwms[0..2]);

print <<EndHTML;
		</tr>
	</table>
</DIV>

EndHTML

close FHO;

1;


#!/usr/bin/perl

use strict;

use FindBin qw($RealBin);

use lib $RealBin;

require 'subroutines.pl';

use LWP::UserAgent ();
use HTTP::Request::Common ();

my ($brsr) = LWP::UserAgent->new();

( my $root = $RealBin) =~ s/\/cgi-bin\/tier3\/mon//; my ($hpath) = '/htdocs/tier3/mon';

local $_ = "@ARGV"; my ($log) = m/\blog\b/i;

my ($time) = time; my ($mtxt);

do {	my ($cach,$cdir,$mode) = @$_; ( $brsr->request( HTTP::Request::Common::GET(
		'http://dashb-nagios-cms.cern.ch/templates/cache/'.($cdir).'/'.($cach).'.png' ),
		$root.$hpath.'/IMAGES/PLOTS/'.( my $inam = 'sam_status_'.($mode)).'.png' )
		)->is_success() || next; &CREATE_THUMB($inam,800,620,1);

	my (%maps); $maps{name} = 'sam_status_'.($mode); my (@maps) = map { my (@crds,@pars);
		(( @crds = /\G(?:.*?COORDS='|,)\s*(\d+\.\d+)\s*/gc ) == 4) && 
		(($pars[0]) = ($mode eq q(hourly)) ? /&testname=([^&']+)/ : undef ) &&
		(($pars[1]) = ($mode eq q(hourly)) ? /&testtimestamp=(\d+)/ : undef ) &&
		(($pars[2]) = /TITLE='[^']*_(\d+)'/ ) &&
		( $maps{xstp} //= ($crds[2]-$crds[0])) && ( $maps{ystp} //= ($crds[3]-$crds[1])) ?
		do {	$maps{xmin} = $crds[0] if ($crds[0] < $maps{xmin}) || !(defined $maps{xmin});
			$maps{ymin} = $crds[1] if ($crds[1] < $maps{ymin}) || !(defined $maps{ymin});
			$maps{xmax} = $crds[2] if ($crds[2] > $maps{xmax});
			$maps{ymax} = $crds[3] if ($crds[3] > $maps{ymax});
			[ @crds[1,0], @pars[0..2]] } :
		(); }
	map { $_->content() =~ m/^cText \+= "(.*)\\n"$/mg } grep { $_->is_success() } $brsr->request(
		HTTP::Request::Common::GET( 'http://dashb-nagios-cms.cern.ch/templates/cache/'.($cdir).'/'.($cach).'.png.js' ));

	do {	my (@test,@stmp,@hour);
		do { if ($mode eq q(hourly)) { $test[$$_[0]] //= $$_[2]; $stmp[$$_[0]][$$_[1]] //= $$_[3]; } $hour[$$_[1]] //= $$_[4]; }
		for map {[ &ROUND(($$_[0]-$maps{ymin})/$maps{ystp},0), &ROUND(($$_[1]-$maps{xmin})/$maps{xstp},0), @$_[2..4] ]} @maps;

		$mtxt .= "\n"; $mtxt .= 'TopUpMap_object.'.($maps{name}).' = new Object();'."\n";
		$mtxt .= 'TopUpMap_object.'.($maps{name}).'.top = '.( &ROUND($maps{ymin},0)).';'."\n";
		$mtxt .= 'TopUpMap_object.'.($maps{name}).'.left = '.( &ROUND($maps{xmin},0)).';'."\n";
		$mtxt .= 'TopUpMap_object.'.($maps{name}).'.ysteps = '.(($mode eq q(hourly))?(0+@test):($mode eq q(daily))?1:0).';'."\n";
		$mtxt .= 'TopUpMap_object.'.($maps{name}).'.xsteps = '.(0+@hour).';'."\n";
		$mtxt .= 'TopUpMap_object.'.($maps{name}).'.iheight = '.( &ROUND($maps{ymax}-$maps{ymin},0)).';'."\n";
		$mtxt .= 'TopUpMap_object.'.($maps{name}).'.iwidth = '.( &ROUND($maps{xmax}-$maps{xmin},0)).';'."\n";
		$mtxt .= 'TopUpMap_object.'.($maps{name}).'.tlines = '.(($mode eq q(hourly))?4:($mode eq q(daily))?3:0).';'."\n";
		$mtxt .= 'TopUpMap_object.'.($maps{name}).'.twidth = '.(($mode eq q(hourly))?210:($mode eq q(daily))?140:0).';'."\n";
		if ($mode eq q(hourly)) {
			$mtxt .= 'TopUpMap_object.'.($maps{name}).'.test = ['.( join q(,),
				map { (defined) ? (q(")).($_).(q(")) : q(null) } @test ).'];'."\n";
			$mtxt .= 'TopUpMap_object.'.($maps{name}).'.hour = ['.( join q(,),
				map { (defined) ? (q(")).( &DATE_FORMAT($_,1,q(%A, %Y-%m-%d %R UTC))).(q(")) : q(null) } @hour ).'];'."\n";
			$mtxt .= 'TopUpMap_object.'.($maps{name}).'.timestamp = ['."\n".( join qq(,\n), (
				map { my ($i) = $_; "\t".'['.( join q(,), map { (defined) ? (q(")).($_).(q(")) : q(null) }
					map { $stmp[$i][$_] } (0..$#hour)).']' } (0..$#test)))."\n".'];'."\n"; }
		elsif ($mode eq q(daily)) {
			$mtxt .= 'TopUpMap_object.'.($maps{name}).'.start = ['.( join q(,),
				map { (defined) ? (q(")).( &DATE_FORMAT($_,1,q(%Y-%m-%d))).(q(")) : q(null) } @hour ).'];'."\n";
			$mtxt .= 'TopUpMap_object.'.($maps{name}).'.end = ['.( join q(,),
				map { (defined) ? (q(")).( &DATE_FORMAT(($_+24*3600),1,q(%Y-%m-%d))).(q(")) : q(null) } @hour ).'];'."\n"; }
		$mtxt .= 'TopUpMap_object.'.($maps{name}).'.link = function (yidx,xidx) {'."\n".( ${{
				hourly =>
					"\t".'var test = TopUpMap_object.sam_status_hourly.test[yidx];'."\n" .
					"\t".'var timestamp = TopUpMap_object.sam_status_hourly.timestamp[yidx][xidx];'."\n" .
					"\t".'if ((test == null) || (timestamp == null)) return null;'."\n" .
					"\t".'return "https://lcg-sam.cern.ch:8443/sam/sam.py?funct=TestResult&nodename=hurr.tamu.edu&vo=CMS' .
						'&testname="+test+"&testtimestamp="+timestamp;'."\n" ,
				daily =>
					"\t".'var start = TopUpMap_object.sam_status_daily.start[xidx];'."\n" .
					"\t".'var end = TopUpMap_object.sam_status_daily.end[xidx];'."\n" .
					"\t".'if ((start == null) || (end == null)) return null;'."\n" .
					"\t".'return "http://dashb-nagios-cms.cern.ch/dashboard/request.py/testhistory?servicename=hurr.tamu.edu' .
						'&timeRange=individual&start="+start+"&end="+end;'."\n" ,
			}}{$mode} ).'};'."\n";
		$mtxt .= 'TopUpMap_object.'.($maps{name}).'.text = function (yidx,xidx) {'."\n".( ${{
				hourly =>
					"\t".'var test = TopUpMap_object.sam_status_hourly.test[yidx];'."\n" .
					"\t".'var timestamp = TopUpMap_object.sam_status_hourly.timestamp[yidx][xidx];'."\n" .
					"\t".'var hour = TopUpMap_object.sam_status_hourly.hour[xidx];'."\n" .
					"\t".'if ((test == null) || (timestamp == null) || (hour == null)) return null;'."\n" .
					"\t".'return "Click for Detailed SAM Test Log<br>"+test+"<br>"+hour+' .
						'"<br>(CERN Security Certificate Required)";'."\n" ,
				daily =>
					"\t".'var start = TopUpMap_object.sam_status_daily.start[xidx];'."\n" .
					"\t".'if (start == null) return null;'."\n" .
					"\t".'return "Click for Hourly Summary<br>All SAM Tests<br>"+start;'."\n" ,
			}}{$mode} ).'};'."\n";
		if ($mode eq q(hourly)) { do { &ALERT(( undef, qw( SAM_FAIL SAM_SKIP ))[$$_[0]],2,($$_[1]//())) } for
			map { my ($code); for ( reverse @$_ ) { last if defined ( $code = ($$_[0] < 5) ? undef :
				($$_[2] < 100*(1-150/(17*$$_[0]))) ? [1,( &ROUND($$_[2],0))] : ($$_[0] < 85) ? undef : 0 ) }
				( $code // [2] ) || () } grep { splice(@$_,0,int(0.95*@$_)); 1 }
			( &SCORE_PLOT( q(sam_status_hourly), [234,51,784,499] ))[1] // []; }
	} if @maps;
# [ @maps{ qw( xmin ymin xmax ymax )}]

} for	map { $$_[0]->is_success() && ( shift @$_ )->content() =~ m/\/([\d_]+)\.png"/s ? [$1,@$_] : () }
	map {[ $brsr->request( HTTP::Request::Common::GET(( shift @$_ ))), @$_ ]} (
		[ 'http://dashb-nagios-cms.cern.ch/dashboard/request.py/testhistory?servicename=hurr.tamu.edu&timeRange=last48', 'TestHistory', 'hourly' ],
		[ 'http://dashb-nagios-cms.cern.ch/dashboard/request.py/historicalsiteavailability?sites=T3_US_TAMU&timeRange=individual' . do {
			my ($step,$span) = (45,86400); my $stop = ($time + $span) - ($time % $span); my $strt = $stop - $step*$span;
			'&start='.( &DATE_FORMAT($strt,1,q(%Y-%m-%d))).'&end='.( &DATE_FORMAT($stop,1,q(%Y-%m-%d))) },
			'HistoricalSiteAvailability', 'daily' ] ); $mtxt .= "\n";

open FHO, '>'.$root.'/htdocs/tier3/mon/JAVASCRIPT/mon_top_up_map_sam_plot.js'; select FHO; print $mtxt; close FHO;

open FHO, '>'.$root.'/htdocs/tier3/mon/SSI/TABLES/sam_plot.ssi'; select FHO;

print <<EndHTML;

<DIV id="sam_plot_anchor" style="z-index:0; display:block; position:static; height:378px; width:826px; margin:0px 0px; padding:0px; text-align:center; overflow:hidden;">
	<table class="mon_default" style="width:826px; height:378px;">
		<tr class="mon_default">
			<td class="mon_default" colspan="2" style="width:810px; height:16px;">Service Availability Monitoring (SAM) Tests</td>
		</tr>
		<tr class="mon_default">
			<td class="mon_default" style="width:400px; height:310px;"><a id="sam_plot_leader" href="IMAGES/PLOTS/sam_status_hourly.png?${time}" target="NEW"><img class="mon_default" src="IMAGES/THUMBS/sam_status_hourly.png?${time}" alt="SAM Test Status Summary (Last 48 Hours)" title="SAM Test Status Summary (Last 48 Hours)" width="400" height="310"></a></td>
			<td class="mon_default" style="width:400px; height:310px;"><a href="IMAGES/PLOTS/sam_status_daily.png?${time}" target="NEW"><img class="mon_default" src="IMAGES/THUMBS/sam_status_daily.png?${time}" alt="SAM Test Site Summary (Last 45 Days)" title="SAM Test Site Summary (Last 45 Days)" width="400" height="310"></a></td>
		</tr>
		<tr class="mon_default">
			<td colspan="2" class="mon_default" style="width:810px; height:16px; color:black; background-color:#FFFFFF; cursor:pointer;" onClick="javascript:TopUp.displayTopUp(document.getElementById('sam_plot_leader'));" onMouseOver="javascript:this.style.backgroundColor=\'#3BB9FF\';" onMouseOut="javascript:this.style.backgroundColor=\'#FFFFFF\';">
				<DIV style="float:left; clear:none; width:50%; margin:0px; padding:0px; text-align:center;">&uarr; Click to Enlarge Images</DIV>
				<DIV style="float:left; clear:none; width:50%; margin:0px; padding:0px; text-align:center;">Enlarged Images Link to Details &uarr;</DIV>
			</td>
		</tr>
	</table>
</DIV>

EndHTML

close FHO;

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
do { my (@cols) = reverse @{ ( &SCORE_PLOT( q(sam_status_daily), [77,200,784,201], [707,1] ))[1] // [] };
	splice (@cols, 0, ( &ROUND((1-( &DATE_FORMAT($time,1,'%H'))/23)*706/45,0))); for (
		map { &ROUND( &AVG( map { $$_[2] } @cols[1..( &ROUND($_*706/45))] ),0) } (1,7,30)) {
			print "\t\t\t".'<td class="mon_default" style="width:82px; height:16px; color:black; background-color:' .
			(($_>=90) ? q(green) : ($_>=80) ? q(orange) : q(red)).';">'.($_).' &#37;</td>'."\n"; }};
print <<EndHTML;
		</tr>
	</table>
</DIV>

EndHTML

close FHO;

1;

# http://dashb-cms-sam.cern.ch


#!/usr/bin/perl

use strict;

use FindBin qw($RealBin);

use lib $RealBin;

require 'subroutines.pl';

( my $root = $RealBin) =~ s/\/cgi-bin\/tier3\/mon//;

my ($cpath) = '/cgi-bin/tier3/mon'; my ($hpath) = '/htdocs/tier3/mon'; my ($opath) = '/OFFLINE/tier3/mon';

my ($log) = "@ARGV" =~ /\blog\b/; my ($norun) = "@ARGV" =~ /\bnorun\b/;

my (@cmds) = qw(
	grab_transfer_plot
	grab_subscription_plot
	grab_job_plot
	grab_sam_plot
	grab_user_plot_data
	grab_transfer_data
	grab_subscription_data
	grab_brazos_data
	grab_cats_data );

unless ($norun) { my (@subp); for (@cmds) { my ($pid) = fork();
	if ($pid) { push @subp, $pid; }
	elsif ($pid == 0) { system($RealBin.'/'.$_.'.pl',$log && 'log'); exit(0); }
	else { die "couldn't fork: $!\n"; }} for (@subp) { waitpid($_,0); }

	my (@prst) = map { ( open FHI, '<'.($root.$opath).'/PERSIST/'.($_).'.dat' ) ?
		[ map { close FHI; chomp; split /\t/ } ( scalar <FHI> )] : undef } ( qw(
			disk_usage_net disk_usage_phedex_local disk_usage_phedex_resident
			disk_usage_phedex_subscribed transfer_rate_prod_hourly ));

	&ALERT(q(DISK_QUOTA),( shift @$_),1,( map { &DATA_FORMAT_BYTES_HUMAN(int,1) } @$_[0,1] )) for
		map { my ($qota) = 59.5*(1024)**4; [( map { (($_>1.20)?4:($_>1.00)?3:($_>1.00)?2:($_>1.00)?1:0) } ($_/$qota))[0],$_,$qota] }
		map {($$_[1])} ($prst[0]//());
# [( map { (($_>1.20)?4:($_>1.00)?3:($_>0.95)?2:($_>0.90)?1:0) }

	&ALERT(q(PHDX_MISMATCH),@$_) for map { (($$_[0] != $$_[1]) && (!($$_[0]) || (( abs (1-($$_[1]/$$_[0]))) > 0.05) || (( abs ($$_[1]-$$_[0])) > 100*(1024)**3))) ?
		[2,1,( map { &DATA_FORMAT_BYTES_HUMAN(int,1) } @$_[0,1] )] : [0] } grep {(@$_==2)} [ map {($$_[1])} grep {(defined)} @prst[1,2]];

	&ALERT(q(PHDX_TRANSFER),@$_) for map { (($$_[2] < 10*(1024)**2) && (($$_[1]-$$_[0]) > 10*(1024)**3) && (!($$_[0]) || ((($$_[1]/$$_[0])-1) > 0.05))) ?
		[2,1,( map { &DATA_FORMAT_BYTES_HUMAN(int,1) } @$_[0..2] )] : [0] } grep {(@$_==3)} [ map {($$_[1])} grep {(defined)} @prst[2..4]];

	} my ($time) = time;

my (@FHO); open $FHO[0], '>'.($root.$hpath).'/all.shtml'; for my $i (1..5) {
	open $FHO[$i], '>'.($root.$hpath).'/page_'.($i).'.shtml'; }

for my $i (0..5) { select $FHO[$i]; print <<EndHTML;

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">

<html>

<head>

<title>Brazos Tier 3 Data Transfer and Job Monitoring Utility</title>

<META HTTP-EQUIV="Content-Type" content="text/html;charset=utf-8">
<META HTTP-EQUIV="Refresh" CONTENT="600">
<META HTTP-EQUIV="Pragma" CONTENT="no-cache">
<META HTTP-EQUIV="Cache-control" CONTENT="no-cache">
<META HTTP-EQUIV="Expires" CONTENT="-1">

<LINK rel="stylesheet" href="CSS/mon.css" type="text/css">

<STYLE type="text/css">
A#page_${i}_top, A#page_${i}_bot,
A#page_${i}_top:link, A#page_${i}_bot:link,
A#page_${i}_top:visited, A#page_${i}_bot:visited {
	border-top: 2px solid black;
	border-bottom: 2px solid black;
	color: #3BB9FF;
	background-color: inherit; }
</STYLE>

<script type="text/javascript" language="JavaScript" src="JAVASCRIPT/mon.js"></script>

<script type="text/javascript" language="JavaScript" src="JAVASCRIPT/top_up/top_up-min.js"></script>

<script type="text/javascript" language="JavaScript" src="JAVASCRIPT/mon_top_up.js"></script>

</head>

<body onLoad="javascript:MonitorInitialize();" style="margin:0px 0px; padding:0px; text-align:center; background-repeat:repeat; background-position:top left; background-image:url('IMAGES/GLOBAL/bg_W.gif');">

<DIV id="tier3_mon_anchor" style="z-index:0; display:block; position:static; height:auto; width:826px; margin:20px auto; padding:0px; text-align:center; overflow:hidden; background-image:none;">

<H1>Brazos Tier 3 Data Transfer and Job Monitoring Utility</H1>

<p>
<!--#include virtual="SSI/GLOBAL/view_page_top.ssi"-->
<br>

<p>
<!--#include virtual="SSI/GLOBAL/time_updated_format.ssi"-->
<br>

<noscript>
<p>
<SPAN style="font-size:18px; font-weight:bold; color:red; background-color:transparent;">
	Warning: You must enable JavaScript for optimal site functionality!
</SPAN>
<br>
</noscript>

EndHTML

} for my $i (0,1) { select $FHO[$i]; print <<EndHTML;

<p>
<hr>

<h2>Data Transfers to the Brazos Cluster</h2>
<p>
<!--#include virtual="SSI/TABLES/transfer_plot.ssi"-->
<br>
<p>
<!--#include virtual="SSI/TABLES/transfer_data.ssi"-->
<br>

EndHTML

} for my $i (0,2) { select $FHO[$i]; print <<EndHTML;

<p>
<hr>

<h2>Data Holdings on the Brazos Cluster</h2>
<p>
<!--#include virtual="SSI/TABLES/subscription_plot.ssi"-->
<br>
<p>
<!--#include virtual="SSI/TABLES/subscription_data.ssi"-->
<br>
<p>
<!--#include virtual="SSI/TABLES/disk_usage_data.ssi"-->
<br>

EndHTML

} for my $i (0,3) { select $FHO[$i]; print <<EndHTML;

<p>
<hr>

<h2>Job Status of the Brazos Cluster</h2>
<p>
<!--#include virtual="SSI/TABLES/job_plot.ssi"-->
<br>
<p>
<!--#include virtual="SSI/TABLES/qstat_data.ssi"-->
<br>
<p>
<!--#include virtual="SSI/TABLES/condorq_data.ssi"-->
<br>
<p>
<!--#include virtual="SSI/TABLES/user_jobs_plot_data.ssi"-->
<br>

EndHTML

} for my $i (0,4) { select $FHO[$i]; print <<EndHTML;

<p>
<hr>

<h2>Service Availability of the Brazos Cluster</h2>
<p>
<!--#include virtual="SSI/TABLES/sam_percentage.ssi"-->
<br>
<p>
<!--#include virtual="SSI/TABLES/heartbeat_data.ssi"-->
<br>
<p>
<!--#include virtual="SSI/TABLES/cluster_load_data.ssi"-->
<br>
<p>
<!--#include virtual="SSI/TABLES/sam_plot.ssi"-->
<br>
<p>
<!--#include virtual="SSI/TABLES/cats_data.ssi"-->
<br>

EndHTML

} for my $i (0,5) { select $FHO[$i];

print "\n<p>\n<hr>\n\n";

print `${root}${cpath}/alert.cgi`;

} for my $i (0..5) { select $FHO[$i]; print <<EndHTML;

<p>
<hr>

<p>
<!--#include virtual="SSI/GLOBAL/view_page_bot.ssi"-->
<br>

</DIV>

</body>

</html>

EndHTML

close $FHO[$i]; }

system("cp ${root}${hpath}/page_1.shtml ${root}${hpath}/index.shtml");

open FHO, '>'.($root.$hpath).'/SSI/GLOBAL/time_updated_format.ssi'; print FHO "\n".'Updated: &nbsp; ' .
	( &DATE_FORMAT($time,1,q(%A, %Y-%m-%d %R UTC))).' &nbsp; &nbsp; &nbsp; &nbsp; ( ' .
	( &DATE_FORMAT($time,!1,q(%A, %Y-%m-%d %R %Z))).' )'."\n\n"; close FHO;

open FHO, '>'.($root.$hpath).'/SSI/GLOBAL/time_updated_unix.ssi'; print FHO $time; close FHO;

1;


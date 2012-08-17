#!/usr/bin/perl

use strict;

use FindBin qw($RealBin);

use lib $RealBin;

require 'subroutines.pl';

( my $root = $RealBin) =~ s/\/cgi-bin\/tier3\/mon//; my ($opath) = '/OFFLINE/tier3/mon'; my ($hpath) = '/htdocs/tier3/mon';

my ($users) = &LOCAL_USER_NAME();

my (@FHO); open $FHO[0], '>'.($root.$hpath).'/users/id.shtml'; open $FHO[1], '>'.($root.$hpath).'/users/name.shtml';

for my $i (0,1) { select $FHO[$i]; my ($tag) = ( qw( id name ))[$i]; print <<EndHTML;

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">

<html>

<head>

<title>Brazos Tier 3 User Database </title>

<META HTTP-EQUIV="Pragma" CONTENT="no-cache">
<META HTTP-EQUIV="Cache-control" CONTENT="no-cache">
<META HTTP-EQUIV="Expires" CONTENT="-1">

<LINK rel="stylesheet" href="CSS/mon.css" type="text/css">

<STYLE type="text/css">
A#page_${tag}_top, A#page_${tag}_bot,
A#page_${tag}_top:link, A#page_${tag}_bot:link,
A#page_${tag}_top:visited, A#page_${tag}_bot:visited {
	border-top: 2px solid black;
	border-bottom: 2px solid black;
	color: #3BB9FF;
	background-color: inherit; }
</STYLE>

</head>

<body style="margin:0px 0px; padding:0px; text-align:center; background-repeat:repeat; background-position:top left; background-image:url('IMAGES/GLOBAL/bg_W.gif');">

<DIV id="tier3_mon_anchor" style="z-index:0; display:block; position:static; height:auto; width:826px; margin:20px auto; padding:0px; text-align:center; overflow:hidden; background-image:none;">

<H1>Brazos Tier 3 User Database</H1>

<p>
<!--#include virtual="SSI/GLOBAL/view_users_top.ssi"-->
<br>

<p>
<hr>

<DIV id="tier3_users_anchor" style="z-index:0; display:block; position:static; height:auto; width:274px; margin:0px 276px; padding:0px; text-align:center; overflow:hidden;">

EndHTML

} do { select $FHO[0];
	print "\t".'<table class="mon_default" style="width:274px; height:auto;">'."\n";
	print "\t\t".'<tr class="mon_default" style="color:black; background-color:#20B2AA;">'."\n";
	print "\t\t\t".'<td class="mon_default" style="width:82px; height:16px;">ID</td>'."\n";
	print "\t\t\t".'<td class="mon_default" style="width:166px; height:16px;">Name</td>'."\n";
	print "\t\t".'</tr>'."\n";
	for ( map { $$_[0] } sort { ($$a[1] <=> $$b[1]) || ($$a[2] cmp $$b[2]) || ($$a[3] <=> $$b[3]) }
		map {[ $_, ( /^cms(\d{4})$/ ? (1,undef,$1) : (0,lc,undef)) ]} keys %$users ) {
		print "\t\t".'<tr class="mon_default">'."\n";
		print "\t\t\t".'<td class="mon_default" style="width:82px; height:16px;">'.($_).'</td>'."\n";
		print "\t\t\t".'<td class="mon_default" style="width:166px; height:16px;">'.( /^cms\d{4}$/ && q(CMS: )) .
			($$users{$_}).'</td>'."\n";
		print "\t\t".'</tr>'."\n"; }
	print "\t".'</table>'."\n";
}; do { select $FHO[1];
	print "\t".'<table class="mon_default" style="width:274px; height:auto;">'."\n";
	print "\t\t".'<tr class="mon_default" style="color:black; background-color:#20B2AA;">'."\n";
	print "\t\t\t".'<td class="mon_default" style="width:166px; height:16px;">Name</td>'."\n";
	print "\t\t\t".'<td class="mon_default" style="width:82px; height:16px;">ID</td>'."\n";
	print "\t\t".'</tr>'."\n";
	for ( map { $$_[0] } sort { ($$a[1] cmp $$b[1]) } map {[ $_, ( &LAST_NAME_FIRST($$users{$_}))[0]]} keys %$users ) {
		print "\t\t".'<tr class="mon_default">'."\n";
		print "\t\t\t".'<td class="mon_default" style="width:166px; height:16px;">'.( /^cms\d{4}$/ && q(CMS: )) .
			($$users{$_}).'</td>'."\n";
		print "\t\t\t".'<td class="mon_default" style="width:82px; height:16px;">'.($_).'</td>'."\n";
		print "\t\t".'</tr>'."\n"; }
	print "\t".'</table>'."\n";
}; for my $i (0,1) { select $FHO[$i]; print <<EndHTML;

</DIV>

<p>
<hr>

<p>
<!--#include virtual="SSI/GLOBAL/view_users_bot.ssi"-->
<br>

</DIV>

</body>

</html>

EndHTML

close $FHO[$i]; }

system("cp ${root}${hpath}/users/id.shtml ${root}${hpath}/users/index.shtml");

1;


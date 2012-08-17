#!/usr/bin/perl

use strict;

use FindBin qw($RealBin);

use lib $RealBin;

require 'subroutines.pl';

# SUBSCRIBED_FILES SUBSCRIBED_BYTES RESIDENT_FILES RESIDENT_BYTES #_DATA_ITEMS #_COMPLETE #_ACTIVE #_OPEN

use Time::Local ();
use LWP::UserAgent ();
use HTTP::Request::Common ();

my ($brsr) = LWP::UserAgent->new();

( my $root = $RealBin) =~ s/\/cgi-bin\/tier3\/mon//; my ($opath) = '/OFFLINE/tier3/mon';

my ($lhour) = my ($time) = time; $lhour -= ($lhour % 3600);

my ($log) = "@ARGV" =~ /\blog\b/;

my ($response) = $brsr->request(HTTP::Request::Common::GET(
	'https://cmsweb.cern.ch/phedex/datasvc/json/prod/subscriptions?node=T3_US_TAMU&create_since=0'),
	$root.$opath.'/DOWNLOAD/subscription_data.txt' );

unless ($response->is_success) { die $response->status_line; }

open FHI, $root.$opath.'/DOWNLOAD/subscription_data.txt';

my (@subs) = grep { ( shift @$_ ) eq q(T3_US_TAMU) }
map {[ @{{ m/"([^"]+)":"?((?<=")[^"]+|\d+)/g }}{ qw( node request name level group time_create priority is_open suspended files node_files bytes node_bytes) } ]}
map { chop; s/^.*"dataset":\[//; s/"subscription":\[\{([^]]*)]}/$1/g; s/{[^{]*block":\[//g; s/\][^}]*}//g; m/\{([^}]*)}/g }
( join '', grep { chomp; 1 } <FHI> );

close FHI;

=pod
outer: while (<FHI>) { next unless /^<tbody>/; inner: while (<FHI>) { last outer if /^<\/tbody>/; chomp; push @subs, map {[
	Time::Local::timegm( map { @$_ || next inner; $$_[4]--; @$_ } [( $$_[10] =~
		/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2}) UTC$/ )[5,4,3,2,1,0]] ), @$_[0,4],
	@{ ${ $rqst{$$_[0]} //= do { my ($response) = $brsr->request(HTTP::Request::Common::GET(
		'https://cmsweb.cern.ch/phedex/prod/Request::View?request='.$$_[0])); next inner unless ($response->is_success);
		scalar { map { $$_[1] => [ $$_[2], &DATA_FORMAT_HUMAN_EXP($$_[3]) // next inner ] }
		map { [ grep { s/&[\w#]*;//g; s/<[^>]*>//g; 1 } m/<td[^>]*>(.*?)<\/td>/g ] }
		( split "\n", ( $response->content =~ m/<tbody>\n(.*?)\n<\/tbody>/s )[0] ) }} }{$$_[2]} // next inner }[0,1],
	0+$$_[5], ( &DATA_FORMAT_HUMAN_EXP((length $$_[6])?$$_[6]:q(0.0 iB)) // next inner ), ( map { 0+ m/^block$/i } $$_[1] ),
	( map { 0+ m/^replica$/i } $$_[7] ), ( map { 0+ m/^active$/i } $$_[8] ), ( map { 0+ m/^yes$/i } $$_[9] ), $$_[2] ]}
	grep { $$_[3] eq 'T3_US_TAMU' } [ grep { s/&[\w#]*;//g; s/<[^>]*>//g; 1 } m/<td[^>]*>(.*?)<\/td>/g ]; }}
=cut

open FHO, '>'.$root.'/htdocs/tier3/mon/SSI/TABLES/subscription_data.ssi'; select FHO;

# 0       1    2     3     4           5        6       7         8     9          10    11
# request name level group time_create priority is_open suspended files node_files bytes node_bytes
my (%grps); for (@subs) { my $grp = $$_[3]; $grps{$grp} //= [];
	$grps{$grp}[0] += $$_[8];
	$grps{$grp}[1] += $$_[10];
	$grps{$grp}[2] += $$_[9];
	$grps{$grp}[3] += $$_[11];
	$grps{$grp}[4] ++;
	$grps{$grp}[5] += ($$_[8] == $$_[9]); }

$grps{Totals} = [ map { my ($i) = $_; &SUM( map { $$_[$i] } ( values %grps )) } (0..5) ];

print <<EndHTML;

<DIV id="subscription_data_anchor" style="z-index:0; display:block; position:static; height:auto; width:826px; margin:0px 0px; padding:0px; text-align:center; overflow:hidden;">
	<table class="mon_default" style="height:auto; width:826px;">
		<tr class="mon_default" style="color:black; background-color:#FFFFFF;">
			<td class="mon_default" style="width:166px; height:16px;">Production Data</td>
			<td colspan="3" class="mon_default" style="width:266px; height:16px;">Subscribed PhEDEx Data</td>
			<td colspan="4" class="mon_default" style="width:358px; height:16px;">Resident PhEDEx Data</td>
		</tr>
		<tr class="mon_default" style="color:black; background-color:#20B2AA;">
			<td class="mon_default" style="width:166px; height:16px;">Group Name</td>
			<td class="mon_default" style="width:82px; height:16px;">Items</td>
			<td class="mon_default" style="width:82px; height:16px;">Files</td>
			<td class="mon_default" style="width:82px; height:16px;">Bytes</td>
			<td class="mon_default" style="width:82px; height:16px;">Items</td>
			<td class="mon_default" style="width:82px; height:16px;">Files</td>
			<td class="mon_default" style="width:82px; height:16px;">Bytes</td>
			<td class="mon_default" style="width:82px; height:16px;">Percent</td>
		</tr>
EndHTML

for ((grep {!/^Totals$/} sort keys %grps),q(Totals)) { my $grp = $grps{$_};
	print "\t\t".'<tr class="mon_default" style="color:black;background-color:'.( q(#20B2AA), q(#44AA44), q(#6688FF))[ /^Totals$/ ? 0 : ($$grp[0] == $$grp[2]) ? 1 : 2 ].';">'."\n";
	print "\t\t\t".'<td class="mon_default" style="width:166px; height:16px;">'.$_.'</td>'."\n";
	print "\t\t\t".'<td class="mon_default" style="width:82px; height:16px;">';
	print join '</td>'."\n\t\t\t".'<td class="mon_default" style="width:82px; height:16px;">', (
		( map { &COMMA(int) } @$grp[4,0] ), &DATA_FORMAT_BYTES_HUMAN($$grp[1],1),
		( map { &COMMA(int) } @$grp[5,2] ), &DATA_FORMAT_BYTES_HUMAN($$grp[3],1),
		(($$grp[0] == $$grp[2]) ? '100.0' : $$grp[1] ? &ROUND(100*$$grp[3]/$$grp[1],1,1) : '0.0').' &#37;' );
	print '</td>'."\n\t\t".'</tr>'."\n"; } print "\t".'</table>'."\n".'</DIV>'."\n\n";

close FHO;

open FHO, '>'.($root.$opath).'/PERSIST/disk_usage_phedex_subscribed.dat'; print FHO q().($time)."\t".($grps{Totals}[1])."\n"; close FHO;
open FHO, '>'.($root.$opath).'/PERSIST/disk_usage_phedex_resident.dat'; print FHO q().($time)."\t" .
	(($grps{Totals}[0] == $grps{Totals}[2]) ? $grps{Totals}[1] : $grps{Totals}[3])."\n"; close FHO;

# exit unless $log; for (@subs) { open FHO, '>>'.$root.$opath.'/TABLES/SUBSCRIPTION_DATA/'.$lhour.'.dat'; print FHO +( join "\t", @$_ )."\n" for @subs; }

#https://cmsweb.cern.ch/phedex/prod/Data::Subscriptions?col=REQUEST&col=ITEM_LEVEL&col=ITEM_NAME&col=NODE_NAME&col=USER_GROUP&col=NODE_FILES&col=NODE_BYTES&col=IS_MOVE&col=TIME_SUSPEND_UNTIL&col=ITEM_OPEN&col=TIME_CREATE&node=1441&reqfilter=&filter=.*&priority=any&suspended=any&custodial=any&group=any&view=global


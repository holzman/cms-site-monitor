#!/usr/bin/perl

use strict;

use FindBin qw($RealBin);

use lib $RealBin;

require 'subroutines.pl';

use Time::Local (); use LWP::UserAgent (); use HTTP::Request::Common ();

my ($brsr) = LWP::UserAgent->new(); $brsr->credentials('brazos.tamu.edu:80', 'Tier3 Grid Restricted', 'tier3', 'skywalker204D');

( my $root = $RealBin) =~ s/\/cgi-bin\/tier3\/mon//; my ($opath) = '/OFFLINE/tier3/mon';

my ($lhour) = my ($time) = (time); $lhour -= ($lhour % 3600);

local ($_) = "@ARGV"; my ($dlog) = m/\blog\b/i; my ($dall) = m/\ball\b/i;

my (@dkey) = ( !(! m/\bdu\b/i), !(! m/\bqstat\b/i), !(! m/\bcondor_?q\b/i), !(! m/\bheartbeat\b/i), !(! m/\bload\b/i));
my ($ckey) = &SUM(@dkey); my (%dkey) = map {( $_ => 1 )} (
	( $dall || $dkey[0] ? q(disk_usage) : ()),
	( $dall || $dkey[1] || !$ckey ? q(qstat) : ()),
	( $dall || $dkey[2] || !$ckey ? q(condorq) : ()),
	( $dall || $dkey[3] || !$ckey ? q(heartbeat) : ()),
	( $dall || $dkey[4] || !$ckey ? q(load) : ()));

my ($trys,$napt,$call,$wait,$awke,%skey,@alid) = (18,10); for my $itry (1..($trys)) { for my $dkey ( sort keys %dkey ) {
	$call++; my ($response) = $brsr->request(HTTP::Request::Common::GET(
		'http://brazos.tamu.edu:80/~ext-jww004/tier3/mon/'.($dkey).'_data.txt'),
		($root.$opath).'/DOWNLOAD/'.($dkey).'_data.txt' ); $skey{$dkey} = 1 if $response->is_success;
	if ($itry == 1) { my ($response) = $brsr->request(HTTP::Request::Common::GET( my ($wkey) =
		'http://brazos.tamu.edu:80/~ext-jww004/cgi-bin/tier3/mon/report_'.$dkey.'_data.pl'));
		my ($cmod,$cmes) = ($response->is_success) ? (( my (undef,@ctnt) = map { m/^(.*)$/mg }
			$response->content())[0] =~ /^(-?\d+):\s*(.*)$/ ) : ();
		unless (defined $cmod) { $alid[0]++; &ALERT( q(CLUSTER_WEB),2,1,($wkey // q(NULL))) }
		elsif ($cmod > 0) { $alid[1]++; &ALERT( q(CLUSTER_ERR),(($cmod > 1)?3:1),1,($cmes // q(NULL)),($wkey // q(NULL))) }
		elsif ($cmod == 0) { ( open FHO, '>'.($root.$opath).'/DOWNLOAD/'.($dkey).'_data.txt' ) &&
			do { print FHO $_."\n" for @ctnt; close FHO; }; $skey{$dkey} = 1 }
		elsif ($cmod == -1) { $wait++; $alid[2]++; &ALERT( q(CLUSTER_NAP),2,1,($wkey // q(NULL))) }
		else { $wait++; $awke++ if ($cmod == -2); next } delete $dkey{$dkey}; }
	elsif ($response->is_success) { delete $dkey{$dkey}; }}}
continue { last unless ( keys %dkey ); sleep ($napt); } do { $alid[3]++; &ALERT( q(CLUSTER_TKO),2,1,$_) } for map {
	${{ disk_usage => q(DISK USAGE), qstat => q(TORQUE QUEUE), condorq => q(CONDOR QUEUE) }}{$_}} ( sort keys %dkey );

do { &ALERT($_,0); } for map { ${[( qw( CLUSTER_WEB CLUSTER_ERR CLUSTER_NAP CLUSTER_TKO ))]}[$_] }
	grep {!($alid[$_])} (($call) ? (0,1,(($awke) ? (2) : ()),(($wait) ? (3) : ())) : ());

my (%data,$data); for my $skey ( sort keys %skey ) { open FHI, ($root.$opath).'/DOWNLOAD/'.($skey).'_data.txt'; while (<FHI>) {
	/^<!(\w+)!>$/ && do { $data = $1; last if ($data eq q(NULL)); $data{$data} = []; next }; next unless (defined $data);
	chomp; push @{ $data{$data}}, [ map { ($_ eq q(-)) ? undef : $_ } ( split "\t" ) ]; } close FHI; }

# TO_DO: GLOBAL STALE / FAIL CHECKUPS
# where are GRAB_ condorq & qstat?
# malform for top 3
# force present for bottom 2 ... only if returns though
# catch > 60 seconds ... real timeouts
# comment on gluster problems
# be sure exits / dies on far end behave as you think
# be sure that du errors are real ... don't repeat for fyi or timeouts
# don't save du's with real system errors
# get info on 60 sec timeouts
# improve error codes
# be sure all child processes (same gid) are shut down

##### DISK USAGE #####

if ((exists $skey{disk_usage}) && 0+( grep {((/^\d+$/) && (0+$_ > 0+&TIME_STAMP(q(CLUSTER_DU),$_)))} ((undef) = ${ $data{DU_TIME}}[0][0] ))) {

my ($du,$phdx) = [undef,{}]; do { my ($path,$byte,@path) = ($du,@$_); while (@path) {
	$path = ${ $$path[1] }{ shift @path } //= [undef,{}]; } $$path[0] = $byte } for
	map {[ 1024*$$_[0], (length $$_[1]) ? ( map { my ($pat1,$pat2) = @{ ${{
		mc			=> [ q(PhEDEx Monte Carlo) ],
		data			=> [ q(PhEDEx CMS Data) ],
		PhEDEx_LoadTest07	=> [ q(PhEDEx Load Tests), sub { $_[0] =~ /^LoadTest07_Debug_(.+)$/ ? $1 : $_[0] } ],
		user			=> [ q(User Output), \&LOCAL_USER_NAME ]
	}}{$$_[0]} // do { unshift @$_, undef; [ (length $$_[2]) ? q(Null) : q(Miscellaneous) ]}};
	( $pat1, (length $$_[1]) ? &{ $pat2 // sub { ucfirst(lc(shift)) }}($$_[1]) : ()) } [( split '/', $$_[1])[1,2]] ) : () ]}
	grep {(@$_==2)} map {[ $$_[0] =~ /^(\d+)$/, $$_[1] =~ /^\/fdata\/hepx\/store((?:\/[^\/]+){0,2}+)$/ ]} @{ $data{DU}};

my (@alrt); do { push @alrt, q(Failure Invoking "DU" as: ).( ${ $data{DU_QUERY}}[0][0]) if
	(!(0+@{ $data{DU}}) or 0+@$_); push @alrt, map { q([TAB]).$_ } @$_; } for [
#	( map { !(length) ? q(Could Not Establish "DU" Page Fault Status) : ($_ > 0) ? q(Experienced ).(($_>1)?($_) .
#		q( Major Page Faults):q(A Major Page Fault)).q( During "DU" Query) : () } ${ $data{DU_TIME}}[0][3]),
	( map { !(length) ? q(Could Not Establish "DU" I/O Error Status) : ($_ > 0) ? q(Experienced ).(($_>1)?($_) .
		q( Input/Output Errors):q(An Input/Output Error)).q( During "DU" Query) : () } ${ $data{DU_ERRORS}}[0][0]),
	( map { !(defined) ? q(Could Not Establish "DU" Run Time) : ($_ > 30*60) ? q(Excessive "DU" Run Time of ) .
		( &TIME_FORMAT_SECONDS_MINUTES($_,1)).q( Minutes - Less Than 5 Expected) : () }
		&TIME_FORMAT_MINUTES_SECONDS( ${ $data{DU_TIME}}[0][1])),
	( map { q(Delayed "DU" Run for ).( &TIME_FORMAT_SECONDS_MINUTES($_,1)).q( Minutes Due to Heavy Cluster Load) }
		grep {($_ > 180*60)} 0+${ $data{DU_DELAY}}[0][1]) ];

&ALERT( q(GRAB_DU),((0+@alrt) ? (2,1,( join q([BR][TAB]*), (q(),@alrt))) : (0)));

open FHO, '>'.($root).'/htdocs/tier3/mon/SSI/TABLES/disk_usage_data.ssi'; select FHO;
print '<DIV id="disk_usage_data_anchor" style="z-index:0; display:block; position:static; height:auto; width:274px; margin:0px 276px; padding:0px; text-align:center; overflow:hidden;">'."\n";
print "\t".'<table class="mon_default" style="height:auto; width:274px;">'."\n";
print "\t\t".'<tr class="mon_default" style="display:block; color:black; background-color:#FFFFFF;">'."\n";
print "\t\t\t".'<td colspan="2" class="mon_default" style="width:258px; height:16px;">HEPX Disk Store Usage</td>'."\n";
print "\t\t".'</tr>'."\n";
print "\t\t".'<tr class="mon_default" style="display:block; color:black; background-color:#20B2AA;">'."\n";
print "\t\t\t".'<td class="mon_default" style="width:166px; height:16px;">Directory</td>'."\n";
print "\t\t\t".'<td class="mon_default" style="width:82px; height:16px;">Bytes</td>'."\n";
print "\t\t".'</tr>'."\n";
my ($i) = 0; for my $dirg ( q(PhEDEx Monte Carlo), q(PhEDEx CMS Data), q(PhEDEx Load Tests), q(User Output), q(Miscellaneous)) {
	my ($path) = ${ $$du[1]}{$dirg} // [undef,{}]; my ($j) = 0; my ($bsum,$tbit);
	for ( sort { ${ ${ $$path[1]}{$b}}[0] <=> ${ ${ $$path[1]}{$a}}[0] } keys %{ $$path[1]}) {
		$bsum += ( my ($byte) = ${ ${ $$path[1]}{$_}}[0] )[0]; $tbit .=
		"\t\t".'<tr class="mon_default" id="disk_usage_data_element_'.$i.'_'.$j.'" style="display:none; color:black; background-color:#'.(( qw( E9FBFA B3F3F0 ))[$j%2]).';">'."\n" .
		"\t\t\t".'<td class="mon_default" style="width:166px; height:16px;">'.$_.'</td>'."\n" .
		"\t\t\t".'<td class="mon_default" style="width:82px; height:16px;">'.( &DATA_FORMAT_BYTES_HUMAN($byte//0,1)).'</td>'."\n" .
		"\t\t".'</tr>'."\n"; } continue { $j++; }
	print "\t\t".'<tr class="mon_default" id="disk_usage_data_select_'.$i.'" style="display:block; color:black; background-color:#30CCAA; cursor:pointer;" onClick="javascript:DiskUsageDataToggle('.$i.');" onMouseOver="javascript:this.style.backgroundColor=\'#3BB9FF\';" onMouseOut="javascript:this.style.backgroundColor=\'#30CCAA\';">'."\n";
	print "\t\t\t".'<td class="mon_default" style="width:166px; height:16px; color:inherit; background-color:transparent;">'."\n";
	print "\t\t\t\t".'<DIV style="position:relative; left:0px; top:0px; width:166px; height:16px; padding:0px; display:block;">'.$dirg."\n";
	print "\t\t\t\t\t".'<DIV id="disk_usage_data_indicator_'.$i.'_0" style="position:absolute; top:-2px; left:0px; display:block;">&rarr;</DIV>'."\n";
	print "\t\t\t\t\t".'<DIV id="disk_usage_data_indicator_'.$i.'_1" style="position:absolute; top:-2px; left:0px; display:none;">&darr;</DIV>'."\n";
	print "\t\t\t\t".'</DIV>'."\n";
	print "\t\t\t".'</td>'."\n";
	print "\t\t\t".'<td class="mon_default" style="width:82px; height:16px; color:inherit; background-color:transparent;">' .
		( &DATA_FORMAT_BYTES_HUMAN(( grep { ($phdx += $_) if ($dirg =~ /^PhEDEx/); 1 } ($$path[0]//$bsum//0))[0],1)).'</td>'."\n";
	print "\t\t".'</tr>'."\n";
	print $tbit; } continue { $i++; }
print "\t\t".'<tr class="mon_default" style="display:block; color:black; background-color:#20B2AA;">'."\n";
print "\t\t\t".'<td class="mon_default" style="width:166px; height:16px;">Total</td>'."\n";
print "\t\t\t".'<td class="mon_default" style="width:82px; height:16px;">'.( &DATA_FORMAT_BYTES_HUMAN($$du[0]//0,1)).'</td>'."\n";
print "\t\t".'</tr>'."\n";
print "\t\t".'<tr class="mon_default" style="display:block; color:black; background-color:#FFFFFF; cursor:pointer;" onClick="javascript:DiskUsageDataToggleAll();" onMouseOver="javascript:this.style.backgroundColor=\'#3BB9FF\';" onMouseOut="javascript:this.style.backgroundColor=\'#FFFFFF\';">'."\n";
print "\t\t\t".'<td colspan="2" class="mon_default" style="width:258px; height:16px; color:inherit; background-color:transparent;">&uarr; Click to Expand or Collapse Table</td>'."\n";
print "\t\t".'</tr>'."\n";
print "\t".'</table>'."\n";
print '</DIV>'."\n";
close FHO;

open FHO, '>'.($root.$opath).'/PERSIST/disk_usage_phedex_local.dat'; print FHO q().($time)."\t".($phdx)."\n"; close FHO;
open FHO, '>'.($root.$opath).'/PERSIST/disk_usage_net.dat'; print FHO q().($time)."\t".($$du[0]//0)."\n"; close FHO;

}

if (exists $data{DU_DENIED}) {

&ALERT( q(DISK_DENIED),((0+@$_) ? (2,1,( join ', ', @$_)) : (0))) for [ map { $$_[0] } @{ $data{DU_DENIED}} ];

}

#shift @{ $data{DF}};
#my (@df) = grep {(@$_ == 5)} map {[ (length $$_[0]) ? $$_[0] : (), ( map { &DATA_FORMAT_HUMAN_EXP($_) // () } @$_[1..3] ), $$_[4] =~ m/^(\d+)%$/ ? $1 : () ]} @{ $data{DF}};
#for (@df) { print join "\t", @$_; print "\n"; }

##### TORQUE QUEUE #####
# 0:Job_ID 1:Owner 2:Queue 3:Status 4:Utilized_Nodes:CPUs 5:Requested_Nodes:CPUs 6:Memory 7:CPU_Time 8:Run_Time 9:Init_Time
# =>
# 0:Job_ID 1:Owner 2:Queue 3:Status 4:CPUs 5:Memory 6:CPU_Time 7:Run_Time 8:Init_Time

if ((exists $skey{qstat}) && 0+( grep {((/^\d+$/) && (0+$_ > 0+&TIME_STAMP(q(CLUSTER_QSTAT),$_)))} ((undef) = ${ $data{QSTAT_TIME}}[0][0] ))) {

my ($dtim) = ( ${ $data{QSTAT_TIME}}[0][0] =~ /^(\d+)$/ ); my (%stll);
 
open FHO, '>'.($root.$opath).'/LOGS/QSTAT_DATA/'.( my $ltim = ( $dtim - ($dtim % 300))).'.dat'; select FHO;
print q().( join "\t", @$_ )."\n" for grep {(@$_ == 9)} map {[
	$$_[0] =~ /^(\d+(?:-\d+)?)$/ ? q().$1 : (), (length $$_[1]) ? $$_[1] : (), ${{ grid => 0, hepx => 1, hepxrt => 2, bgsc => 3, bgscrt => 4 }}{$$_[2]} // (),
	${{ 'Q' => 0, 'R' => 1, 'C' => 2, 'E' => 3, 'S' => 4, 'H' => 5, 'W' => 6, 'T' => 7 }}{$$_[3]} // (), $$_[4] =~ /^\d+:(\d+)$/ ?
		0+$1 : ($$_[3]==0) ? $$_[5] =~ /^\d+:(\d+)$/ && 0+$1 : (), &DATA_FORMAT_HUMAN_BYTES($$_[6]) // ($$_[3]!=0) && (),
	&TIME_FORMAT_HOURS_SECONDS($$_[7]) // ($$_[3]!=0) && (), &TIME_FORMAT_HOURS_SECONDS($$_[8]) // ($$_[3]!=0) && (),
	( map { @$_ && defined( $$_[4] = ${{Jan=>0,Feb=>1,Mar=>2,Apr=>3,May=>4,Jun=>5,Jul=>6,Aug=>7,Sep=>8,Oct=>9,Nov=>10,Dec=>11}}{$$_[4]} ) ?
		Time::Local::timelocal(@$_) : () } [( $$_[9] =~ m/^[A-Z]+_([A-Z]+)_(\d+)_(\d{2}):(\d{2}):(\d{2})_(\d{4})$/i )[4,3,2,1,0,5]] ),
	]} @{ $data{QSTAT}}; close FHO;

open FHO, '>'.($root).'/htdocs/tier3/mon/SSI/TABLES/qstat_data.ssi'; print FHO &QUEUE_TABLE(0,$ltim,\%stll); close FHO;

&ALERT( q(TORQUE_STALL),@$_) for map { (0+@$_) ? (@$_ == 1) ? [2,1,$$_[0]] : [4,1,q(MULTIPLE)] : [0] } [ keys %stll ];

}

##### CONDOR QUEUE #####
# 0:ClusterId 1:ProcId 2:Owner 3:JobUniverse 4:JobStatus 5:RequestCpus 6:ImageSize
# 7:RemoteUserCpu 8:RemoteSysCpu 9:RemoteWallClockTime 10:CumulativeSuspensionTime 11:QDate 12:CompletionDate
# =>
# 0:Job_ID 1:Owner 2:Universe 3:Status 4:CPUs 5:Memory 6:CPU_Time 7:Run_Time 8:Init_Time 9:Complete_Time

if ((exists $skey{condorq}) && 0+( grep {((/^\d+$/) && (0+$_ > 0+&TIME_STAMP(q(CLUSTER_CONDORQ),$_)))} ((undef) = ${ $data{CONDORQ_TIME}}[0][0] ))) {

my ($dtim) = ( ${ $data{CONDORQ_TIME}}[0][0] =~ /^(\d+)$/ ); my (%stll);

open FHO, '>'.($root.$opath).'/LOGS/CONDORQ_DATA/'.( my $ltim = ( $dtim - ($dtim % 300))).'.dat'; select FHO;
print q().( join "\t", @$_ )."\n" for grep {(@$_ == 10)} map {[
	$$_[0] =~ /^\d+$/ && $$_[1] =~ /^\d+$/ ? ($$_[0]).q(:).($$_[1]) : (), (length $$_[2]) ? $$_[2] : (),
	$$_[3] =~ /^(\d+)$/ && ($1>=0) && ($1<=14) ? 0+$1 : (), $$_[4] =~ /^(\d+)$/ && ($1>=0) && ($1<=6) ? 0+$1 : (),
	$$_[5] =~ /^(\d+)$/ ? 0+$1 : (), $$_[6] =~ /^(\d+)$/ ? $1*1024 : (), $$_[7] =~ /^\d+$/ && $$_[8] =~ /^\d+$/ ? $$_[7]+$$_[8] : (),
	$$_[9] =~ /^\d+$/ && $$_[10] =~ /^\d+$/ ? $$_[9]-$$_[10] : (), $$_[11] =~ /^(\d+)$/ ? 0+$1 : (), $$_[12] =~ /^(\d+)$/ ? 0+$1 : (),
	]} @{ $data{CONDORQ}}; close FHO;

open FHO, '>'.($root).'/htdocs/tier3/mon/SSI/TABLES/condorq_data.ssi'; print FHO &QUEUE_TABLE(1,$ltim,\%stll); close FHO;

&ALERT( q(CONDOR_STALL),@$_) for map { (0+@$_) ? (@$_ == 1) ? [2,1,$$_[0]] : [4,1,q(MULTIPLE)] : [0] } [ keys %stll ];

}

##### CLUSTER HEARTBEAT #####

if ((exists $skey{heartbeat}) && 0+( grep {((/^\d+$/) && (0+$_ > 0+&TIME_STAMP(q(CLUSTER_HEARTBEAT),$_)))} ((undef) = ${ $data{HEARTBEAT_TIME}}[0][0] ))) {

my ($dftt) = q(98.2 TiB); my ($dtim) = map {($_ - ($_ % 300))} ${ $data{HEARTBEAT_TIME}}[0][0]; my (@alrt,@htxt);
(${ $data{HEARTBEAT_HURR}}[0][0] eq q(1)) && ($htxt[0] = [2,q(Pass)]) or push @alrt, q(Cannot SSH to hurr.tamu.edu from brazos.tamu.edu);
(${ $data{HEARTBEAT_GLUSTER}}[0][0] eq q(1)) && ($htxt[1] = [2,q(Pass)]) or push @alrt, q(Cannot Detect FData Filesystem Mount);
do { push @alrt, map { @$_ or $htxt[2][0] = 2; @$_; } [( ((shift @$_) ?  q(Failure Invoking "DF" as: ) .
	( ${ $data{HEARTBEAT_DF_QUERY}}[0][0]) : ()), do { @$_ and $htxt[2][0] = 1; @$_ } )] } for
		[ map { (length) ? ( map { $htxt[2][1] = $_; ($_ eq $dftt) ? () :
			(1, q([TAB]Disk Partition of ).($_).q( Differs From Expected ).($dftt)) }
		q().( &DATA_FORMAT_BYTES_HUMAN(1024*$_,1))) : (1) } ${ $data{HEARTBEAT_DF}}[0][0]];
do { push @alrt, q(Failure Invoking "DU" as: ).( ${ $data{HEARTBEAT_DU_QUERY}}[0][0]) if
	((${ $data{HEARTBEAT_DU}}[0][0] ne '1') or 0+@$_); push @alrt, map { q([TAB]).$_ } @$_; } for [
#	( map { !(length) ? do { q(Could Not Establish "DU" Page Fault Status) } : ($_ > 0) ?
#		do { $htxt[3] = [1,($_).q( Page Fault).(($_>1) && q(s))]; q(Experienced ).(($_>1)?($_) .
#			q( Major Page Faults):q(A Major Page Fault)).q( During "DU" Query) } :
#		do { $htxt[3] = [2,q(Pass)]; () }} ${ $data{HEARTBEAT_DU_TIME}}[0][3]),
#	( map { !(length) ? do { undef $htxt[3]; q(Could Not Establish "DU" I/O Error Status) } : ($_ > 0) ?
#		do { $htxt[3] = [1,($_).q( I/O Error).(($_>1) && q(s))] if (defined $htxt[3]); q(Experienced ).(($_>1)?($_) .
#			q( Input/Output Errors):q(An Input/Output Error)).q( During "DU" Query) } :
#		do { () }} ${ $data{HEARTBEAT_DU_ERRORS}}[0][0]),
	( map { !(length) ? do { q(Could Not Establish "DU" I/O Error Status) } : ($_ > 0) ?
		do { $htxt[3] = [1,($_).q( I/O Error).(($_>1) && q(s))]; q(Experienced ).(($_>1)?($_) .
			q( Input/Output Errors):q(An Input/Output Error)).q( During "DU" Query) } :
		do { $htxt[3] = [2,q(Pass)]; () }} ${ $data{HEARTBEAT_DU_ERRORS}}[0][0]),
	( map { !(defined) ? q(Could Not Establish "DU" Run Time) : do { $htxt[4][1] = ($_).q( Seconds);
		($_ > 15) ? do { $htxt[4][0] = 1; q(Excessive "DU" Run Time of ).($_).q( Seconds - Much Less Than 1 Expected) } :
		do { $htxt[4][0] = 2; () }}} &TIME_FORMAT_MINUTES_SECONDS( ${ $data{HEARTBEAT_DU_TIME}}[0][1])) ];
&ALERT( q(GRAB_HEART),((0+@alrt) ? (2,1,( join q([BR][TAB]*), (q(),@alrt))) : (0)));

open FHO, '>'.($root).'/htdocs/tier3/mon/SSI/TABLES/heartbeat_data.ssi'; select FHO;
print '<DIV id="heartbeat_anchor" style="z-index:0; display:block; position:static; height:84px; width:826px; margin:0px 0px; padding:0px; text-align:center; overflow:hidden;">'."\n";
print "\t".'<table class="mon_default" style="height:84px; width:826px;">'."\n";
print "\t\t".'<tr class="mon_default" style="display:block; color:black; background-color:#FFFFFF;">'."\n";
print "\t\t\t".'<td colspan="5" class="mon_default" style="width:810px; height:16px;">Brazos Cluster Heartbeat Tests ( '.( &DATE_FORMAT($dtim,1,q(%Y-%m-%d %R UTC))).' )</td>'."\n";
print "\t\t".'</tr>'."\n";
print "\t\t".'<tr class="mon_default" style="display:block; color:black; background-color:#20B2AA;">'."\n";
print "\t\t\t".'<td class="mon_default" style="width:154px; height:16px;">SSH Link to Hurr</td>'."\n";
print "\t\t\t".'<td class="mon_default" style="width:154px; height:16px;">FData Filesystem Mount</td>'."\n";
print "\t\t\t".'<td class="mon_default" style="width:154px; height:16px;">FData Partition Size</td>'."\n";
print "\t\t\t".'<td class="mon_default" style="width:154px; height:16px;">"DU" Query Status</td>'."\n";
print "\t\t\t".'<td class="mon_default" style="width:154px; height:16px;">"DU" Query Timer</td>'."\n";
print "\t\t".'</tr>'."\n";
print "\t\t".'<tr class="mon_default" style="display:block; color:black; background-color:#FFFFFF;">'."\n";
print "\t\t\t".'<td class="mon_default" style="width:154px; height:16px; color:black; background-color:'.(( qw( red orange green ))[ $htxt[$_][0]//0]).';">'.($htxt[$_][1]//q(Fail)).'</td>'."\n" for (0..4);
print "\t\t".'</tr>'."\n";
print "\t".'</table>'."\n";
print '</DIV>'."\n";
close FHO;

}

##### CLUSTER LOAD #####

if ((exists $skey{load}) && 0+( grep {((/^\d+$/) && (0+$_ > 0+&TIME_STAMP(q(CLUSTER_LOAD),$_)))} ((undef) = ${ $data{LOAD_TIME}}[0][0] ))) {

my ($dtim) = map {($_ - ($_ % 300))} ${ $data{LOAD_TIME}}[0][0];
my (@nlod) = map { ( map { (defined) ? ( &COMMA( &ROUND(100*$_,1,1))).q( &#37;) : q(-) } ( &SAFE_RATIO($$_[0],$$_[1])))[0].q( of ).((length $$_[2]) ? $$_[2] : q(-)) }
	map {	[$$_[0],$$_[1],&COMMA($$_[1])], [$$_[2],$$_[3],&COMMA($$_[3])], [$$_[4],$$_[5],&COMMA($$_[5])],
		[$$_[6],$$_[7],&DATA_FORMAT_BYTES_HUMAN(1024*$$_[7],1)], [$$_[8],$$_[9],&DATA_FORMAT_BYTES_HUMAN(1024*$$_[9],1)] }
	${ $data{LOAD_NODE_UTILIZATION}}[0];
my (@glod) = map { (length) ? $_ : q(-) } ( ${ $data{LOAD_BRAZOS}}[0][0], ${ $data{LOAD_HURR}}[0][0],
	( &COMMA(${ $data{LOAD_GRIDFTP_PROCESSES}}[0][0]) // q()),
	( map { !(!(length)) && ($_).q( &#37;) } @{ $data{LOAD_GLUSTERFS}[0]}[0,1]));

open FHO, '>'.($root).'/htdocs/tier3/mon/SSI/TABLES/cluster_load_data.ssi'; select FHO;
print '<DIV id="cluster_load_anchor" style="z-index:0; display:block; position:static; height:auto; width:826px; margin:0px 0px; padding:0px; text-align:center; overflow:hidden;">'."\n";
print "\t".'<table class="mon_default" style="height:auto; width:826px;">'."\n";
print "\t\t".'<tr class="mon_default" style="display:block; color:black; background-color:#FFFFFF;">'."\n";
print "\t\t\t".'<td colspan="5" class="mon_default" style="width:810px; height:16px;">Brazos Cluster Load Statistics ( '.( &DATE_FORMAT($dtim,1,q(%Y-%m-%d %R UTC))).' )</td>'."\n";
print "\t\t".'</tr>'."\n";
print "\t\t".'<tr class="mon_default" style="display:block; color:black; background-color:#20B2AA;">'."\n";
print "\t\t\t".'<td class="mon_default" style="width:154px; height:16px;">Brazos Head Load</td>'."\n";
print "\t\t\t".'<td class="mon_default" style="width:154px; height:16px;">Hurr Head Load</td>'."\n";
print "\t\t\t".'<td class="mon_default" style="width:154px; height:16px;">GridFTP Processes</td>'."\n";
print "\t\t\t".'<td class="mon_default" style="width:154px; height:16px;">Filesystem CPU Use</td>'."\n";
print "\t\t\t".'<td class="mon_default" style="width:154px; height:16px;">Filesystem Memory Use</td>'."\n";
print "\t\t".'</tr>'."\n";
print "\t\t".'<tr class="mon_default" style="display:block; color:black; background-color:#E9FBFA;">'."\n";
print "\t\t\t".'<td class="mon_default" style="width:154px; height:16px;">'.($glod[$_]).'</td>'."\n" for (0..4);
print "\t\t".'</tr>'."\n";
print "\t\t".'<tr class="mon_default" style="display:block; color:black; background-color:#20B2AA;">'."\n";
print "\t\t\t".'<td class="mon_default" style="width:154px; height:16px;">Occupied Nodes</td>'."\n";
print "\t\t\t".'<td class="mon_default" style="width:154px; height:16px;">Occupied Processors</td>'."\n";
print "\t\t\t".'<td class="mon_default" style="width:154px; height:16px;">Load Average per CPU</td>'."\n";
print "\t\t\t".'<td class="mon_default" style="width:154px; height:16px;">Physical Memory Use</td>'."\n";
print "\t\t\t".'<td class="mon_default" style="width:154px; height:16px;">Virtual Memory Use</td>'."\n";
print "\t\t".'</tr>'."\n";
print "\t\t".'<tr class="mon_default" style="display:block; color:black; background-color:#E9FBFA;">'."\n";
print "\t\t\t".'<td class="mon_default" style="width:154px; height:16px;">'.($nlod[$_]).'</td>'."\n" for (0..4);
print "\t\t".'</tr>'."\n";
print "\t\t".'<tr class="mon_default" style="display:block; color:black; background-color:#20B2AA;">'."\n";
print "\t\t\t".'<td class="mon_default" style="width:154px; height:16px;">Queue</td>'."\n";
print "\t\t\t".'<td class="mon_default" style="width:154px; height:16px;">Job Capacity</td>'."\n";
print "\t\t\t".'<td class="mon_default" style="width:154px; height:16px;">Jobs Running</td>'."\n";
print "\t\t\t".'<td class="mon_default" style="width:154px; height:16px;">Jobs Queued</td>'."\n";
print "\t\t\t".'<td class="mon_default" style="width:154px; height:16px;">Other Jobs</td>'."\n";
print "\t\t".'</tr>'."\n";
my ($i) = 0; for (@{ $data{LOAD_QUEUE_UTILIZATION}}) { my (@qlod) = @$_;
	$qlod[0] = ${{ hepxrt => q(HEPX ROUTING), bgscrt => q(BGSC ROUTING) }}{$qlod[0]} // (uc $qlod[0]); @qlod[1..4] = map { &COMMA($_) } @qlod[1..4];
	print "\t\t".'<tr class="mon_default" style="display:block; color:black; background-color:#'.(( qw( E9FBFA B3F3F0 ))[($i++)%2]).';">'."\n";
	print "\t\t\t".'<td class="mon_default" style="width:154px; height:16px;">'.($qlod[$_]).'</td>'."\n" for (0..4); print "\t\t".'</tr>'."\n"; }
print "\t".'</table>'."\n";
print '</DIV>'."\n";
close FHO;

}

#exit unless $dlog; for (@subs) { open FHO, '>>'.$root.$opath.'/TABLES/SUBSCRIPTION_DATA/'.$lhour.'.dat'; print FHO +( join "\t", @$_ )."\n" for @subs; }

1;


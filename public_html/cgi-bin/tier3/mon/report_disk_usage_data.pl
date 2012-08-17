#!/usr/bin/perl

use strict; my ($ldir) = q(/home/ext-jww004);

use Fcntl qw( :DEFAULT :flock ); use POSIX qw( setsid strftime );

print "Content-type: text/html\n\n";

sysopen my $FHL, $0, O_RDONLY or do { print '1: Error Opening Self ... Exiting'."\n"; exit 1 };

flock $FHL, LOCK_EX | LOCK_NB or do { print '1: Error Locking Self ... Exiting'."\t\t\n".'* Probably Still Busy With Prior "DU" After About 6 Hours'."\n"; exit 1 };

system('rm '.($ldir).'/public_html/tier3/mon/disk_usage_data.txt > /dev/null 2>&1');

print +( my $dlay = 0+&DELAY()) ? '-1: Dispatching to Background ... Hibernating'."\n" : '-2: Dispatching to Background ... Running'."\n";

chdir('/') && open(STDIN,'<','/dev/null') && open(STDOUT,'>','/dev/null') && open(STDERR,'>','/dev/null') &&
	( map { (defined) && (!$_) } fork())[0] or exit(0); setsid(); umask(0022);

my ($ntim) = 600; while ($dlay) { sleep $ntim; last unless &DELAY(); $dlay++; }

my ($tdir) = q(/fdata/hepx/store); my ($line);

my ($dtim,$stim) = map {( $_, strftime('%A, %d-%b-%Y %H:%M:%S %Z', localtime($_)) )} (time);

$line .= '<!DU!>'."\n";

$line .= `${\( '/usr/bin/time -f "DU_TIME\t%E\t%P\t%F\t%W" -o '.($ldir).'/public_html/OFFLINE/tier3/mon/disk_usage_time.txt ' .
	'/usr/bin/du --max-depth=2 '.($tdir).' 2> '.($ldir).'/public_html/OFFLINE/tier3/mon/disk_usage_errors.txt' )}`;

$line .= '<!DU_DENIED!>'."\n";

$line .= join q(), map { $_."\n" } map { my (%dend) = map {( $_ => 1 )} @$_; sort keys %dend } [
	map { m/cannot read directory `${tdir}((?:\/[^\/']+){1,2})[^']*': Permission denied/g }
	(( open FHI, ($ldir).'/public_html/OFFLINE/tier3/mon/disk_usage_errors.txt' ) ?
		@{ ([ grep { chomp; 1 } <FHI> ], ( close FHI ))[0] } : ()) ];

$line .= '<!DU_ERRORS!>'."\n";

$line .= (0+@$_)."\n" for [ grep { /Input\/output error/ }
        (( open FHI, ($ldir).'/public_html/OFFLINE/tier3/mon/disk_usage_errors.txt' ) ?
                @{ ([ grep { chomp; 1 } <FHI> ], ( close FHI ))[0] } : ()) ];

$line .= '<!DU_DELAY!>'."\n";

$line .= ($dlay*$ntim)."\n";

$line .= '<!DU_TIME!>'."\n";
#Stamp  Wall    %CPU    Faults  Swaps

$line .= $_ for map { ( join "\t", ($dtim,@$_[0..3]))."\n" }
	grep { ( open FHO, '>>', ($ldir).'/LOGS/time_disk_usage.txt' ) &&
		( print FHO q().( join "\t", ($dtim,@$_[0..3],$stim))."\n" ) && ( close FHO ); 1 }
	(( open FHI, ($ldir).'/public_html/OFFLINE/tier3/mon/disk_usage_time.txt' ) ? ([ map { chomp;
	(( split "\t" ), undef )[0..3] } ( grep { s/^DU_TIME\t//; } <FHI> )[0]], ( close FHI ))[0] : ());

$line .= '<!DU_QUERY!>'."\n";

$line .= '/usr/bin/du --max-depth=2 '.($tdir)."\n";

#$line .= '<!DF!>'."\n";

#$line .= `/bin/df`;

$line .= '<!NULL!>'."\n";

open FHO, '>', ($ldir).'/public_html/tier3/mon/disk_usage_data.txt' or die 'Cannot Open File ... Exiting';

print FHO $line;

close FHO;

sub DELAY { my (%data,$data);
	do { /^<!(\w+)!>$/ && do { $data = $1; last if ($data eq q(NULL)); $data{$data} = []; next };
		next unless (defined $data); push @{ $data{$data}}, [( split "\t" )]; }
	for map { m/^(.*)$/mg } `${ldir}/public_html/cgi-bin/tier3/mon/report_load_data.pl`;
	( return 1 ) unless ( 3 == ( my ($lqur,$lgfs,$lgfp) = grep {(defined)}
		@data{ qw( LOAD_QUEUE_UTILIZATION LOAD_GLUSTERFS LOAD_GRIDFTP_PROCESSES )} ));
	((( &SUM(@{ $$lqur[0]}[2,3],@{ $$lqur[1]}[2,3]))/( &SUM($$lqur[0][1],$$lqur[1][1]) || 1 )) > 1.25) ||
#	($$lgfs[0][0] > 80) ||
	($$lgfp[0][0] > 8) and
	return 1; 0 }

sub SUM { my ($sum) = 0; $sum += $_ for @_; $sum }

1;


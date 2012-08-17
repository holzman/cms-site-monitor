#!/usr/bin/perl

use strict; my ($ldir) = q(/home/ext-jww004);

use Fcntl qw(:DEFAULT :flock); use POSIX qw(setsid);

print "Content-type: text/html\n\n";

sysopen my $FHL, $0, O_RDONLY or do { print '1: Error Opening Self ... Exiting'."\n"; exit 1 };

flock $FHL, LOCK_EX | LOCK_NB or do { print '1: Error Locking Self ... Exiting'."\n"; exit 1 };

system('rm '.($ldir).'/public_html/tier3/mon/qstat_data.txt > /dev/null 2>&1');

print '-3: Dispatching to Background ... Running'."\n";

chdir('/') && open(STDIN,'<','/dev/null') && open(STDOUT,'>','/dev/null') && open(STDERR,'>','/dev/null') &&
	( map { (defined) && (!$_) } fork())[0] or exit(0); setsid(); umask(0022);

my ($dtim) = (time);

system('/usr/local/bin/qstat -f1 grid hepx hepxrt bgsc bgscrt > '.($ldir).'/public_html/OFFLINE/tier3/mon/qstat_data_raw.txt');

my @qkey = ( 'Job_Owner', 'queue', 'job_state', 'exec_host', 'Resource_List.nodes', 'resources_used.mem',
	'resources_used.cput', 'resources_used.walltime', 'etime' ); my %qkey = map {( $_ => 1 )} @qkey;

open FHI, ($ldir).'/public_html/OFFLINE/tier3/mon/qstat_data_raw.txt';

my ($qstt,%qstt); while (<FHI>) {
	if (/^Job Id:\s+(\d+(?:-\d+)?)\.brazos\.tamu\.edu$/) { $qstt = $qstt{$1} = {}; next; }
	my ($qkey,$qval) = (/^\s+([^\s]+)\s+=\s+(.*)$/) or next; $qkey{$qkey} or next;
	$$qstt{$qkey} = &{ ${{
		'Job_Owner'		=> sub { ( grep { s/\@.*$//; 1 } (shift))[0] },
		'exec_host'		=> sub { my $i = 0; ( 0+ keys %{{ map { $i++; ( $_ => 1 )}
				map {( m/^(\w+)\/\d+$/ )} map {( split /\+/ )} (shift) }}).':'.$i },
		'Resource_List.nodes'	=> sub { (shift) =~ /^(\d+)(?::ppn=(\d+))?/ or return;
				$1.(!(!(length $2)) && ':'.($1*$2)) },
	}}{$qkey} or sub { (shift) }} ($qval); }

close FHI;

my ($line);

$line .= '<!QSTAT_TIME!>'."\n".($dtim)."\n";

$line .= '<!QSTAT!>'."\n";

for ( map {( shift @$_ )} sort { ($$a[1]<=>$$b[1]) || ($$a[2]<=>$$b[2]) } map {[ $_, split /-/ ]} keys %qstt ) { $line .= '' .
	( join "\t", ( $_, ( map { (defined $_) ? $_ : q(-) } grep { s/\s+/_/g; 1 } @{ $qstt{$_}}{@qkey} )))."\n"; }

$line .= '<!NULL!>'."\n";

open FHO, '>', ($ldir).'/public_html/tier3/mon/qstat_data.txt' or die 'Cannot Open File ... Exiting';

print FHO $line;

close FHO;

1;


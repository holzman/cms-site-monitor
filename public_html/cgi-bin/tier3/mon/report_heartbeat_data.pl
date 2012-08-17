#!/usr/bin/perl

use strict; my ($ldir) = q(/home/ext-jww004); my ($task) = q(heartbeat);

use Fcntl qw( :DEFAULT :flock );

print "Content-type: text/html\n\n" if exists $ENV{REQUEST_METHOD};

sysopen my $FHL, $0, O_RDONLY or do { print '1: Error Opening Self ... Exiting'."\n"; exit 1 };

do { ( flock $FHL, LOCK_EX | LOCK_NB ) ? last : $_ ? ( sleep 5 ) : do {
	print '1: Error Locking Self ... Exiting'."\n"; exit 1 }} for ( reverse (0..6));

do { my ($pidf) = grep {(defined)} fork() or do { print '2: Error Forking Process ... Exiting'."\n"; exit 2 };
	do { setpgrp(0,0); exec (($ldir).'/public_html/cgi-bin/tier3/mon/'.($task).'.sh > ' .
		($ldir).'/public_html/OFFLINE/tier3/mon/'.($task).'_data_tmp.txt'); exit 0 } if ($pidf == 0);
	eval { local $SIG{ALRM} = sub { die }; alarm 60; waitpid ($pidf,0); alarm 0; 1 } or do {
		system ('kill -TERM -'.($pidf)); waitpid ($pidf,0);
		print '2: Error Completing Task Within 60 Seconds ... Exiting'."\n"; exit 2 };
	system ('cp '.($ldir).'/public_html/OFFLINE/tier3/mon/'.($task).'_data_tmp.txt ' .
		($ldir).'/public_html/OFFLINE/tier3/mon/'.($task).'_data.txt'); }
if (((time) - ( stat +($ldir).'/public_html/OFFLINE/tier3/mon/'.($task).'_data.txt' )[9] ) > 90 );

print '0: Servicing Query ... Spooling Data'."\n" .
	(( open FHI, ($ldir).'/public_html/OFFLINE/tier3/mon/'.($task).'_data.txt' ) ?
	(( join '', <FHI> ), ( close FHI ))[0] : undef );

1;

# SINGLE PROCESS GROUP ID IS BREAKING ... FROM TIME ?


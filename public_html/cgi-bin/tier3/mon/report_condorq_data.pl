#!/usr/bin/perl

use strict; my ($ldir) = q(/home/ext-jww004);

use Fcntl qw(:DEFAULT :flock); use POSIX qw(setsid);

print "Content-type: text/html\n\n";

sysopen my $FHL, $0, O_RDONLY or do { print '1: Error Opening Self ... Exiting'."\n"; exit 1 };

flock $FHL, LOCK_EX | LOCK_NB or do { print '1: Error Locking Self ... Exiting'."\n"; exit 1 };

system('rm '.($ldir).'/public_html/tier3/mon/condorq_data.txt > /dev/null 2>&1');

print '-3: Dispatching to Background ... Running'."\n";

chdir('/') && open(STDIN,'<','/dev/null') && open(STDOUT,'>','/dev/null') && open(STDERR,'>','/dev/null') &&
	( map { (defined) && (!$_) } fork())[0] or exit(0); setsid(); umask(0022);

system('ssh hurr.tamu.edu '.($ldir).'/public_html/cgi-bin/tier3/mon/condorq.sh > '.($ldir).'/public_html/tier3/mon/condorq_data.txt');

1;


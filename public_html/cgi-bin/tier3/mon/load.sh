#!/bin/bash

echo "<!LOAD_TIME!>"
#TimeStamp

/bin/date +%s

echo "<!LOAD_BRAZOS!>"
#Load

uptime | perl -ne '/(\d+\.\d+)$/; print $1."\n";';

echo "<!LOAD_HURR!>"
#Load

ssh hurr.tamu.edu uptime 2>/dev/null | perl -ne '/(\d+\.\d+)$/; print $1."\n";';

echo "<!LOAD_QUEUE_UTILIZATION!>"
#Queue	MaxRun	Running	Queued	Other

qstat -Q grid hepx hepxrt bgsc bgscrt | grep -vP "Queue|---" | perl -ne \
	'chomp; print +( join "\t", map {(@$_[0,1,6,5],($$_[2]-$$_[5]-$$_[6]))} [ split /\s+/ ])."\n";'

echo "<!LOAD_NODE_UTILIZATION!>"
#Active	Nodes	Active	Procs	Active	Cores	Active	PMem	Active	VMem

qnodes | perl -ne \
	'END { print +( join "\t", @qndt )."\n" }
	/^c\d+[a-z]?$/ ? do { ($free,$proc,$jobs) = (); } :
	/^\s+state = (free$)?/ ? $free = !(!$1) :
	/^\s+np = (\d+)$/ ? $proc = 0+$1 :
	/^\s+jobs = (.*)$/ ? $jobs = 0+( grep { /^\d+\// } (split /,\s+/, $1)) :
	/^\s+status = (.*)$/ ? do { do {
		$qndt[0] += ((shift @$_) ne q(0)); $qndt[1]++; $qndt[2] += (($free) ? $jobs : $proc);
		$qndt[3] += $proc; $qndt[4] += (shift @$_); $qndt[5] += (shift @$_);
		s/kb$// for (@$_); $qndt[7] += $$_[0]; $qndt[9] += ($$_[1] - $$_[0]);
		do { $qndt[6] += $$_[0]; $qndt[8] += ($$_[1] - $$_[0]); } for [
			map {(( sort {$a <=> $b} @$_ )[0],$$_[1])} [$$_[0],$$_[1]-$$_[2]]]; } for [
		@{{ map {( /^([a-z]+)=(.*)$/ )} (split /\,/, $1) }}{ qw( nusers loadave ncpus physmem totmem availmem )}] } :
	undef ; ';

echo "<!LOAD_GLUSTERFS!>"
#%CPU	%MEM	VSZ	RSS

ssh hurr.tamu.edu ps -o pcpu,pmem,vsz,rss,comm -A 2>/dev/null | grep " fhgfs_" | perl -ne \
	'print +( join "\t", ( split /\s+/ )[1..4])."\n"';

echo "<!LOAD_GRIDFTP_PROCESSES!>"
#Count

ssh hurr.tamu.edu ps -C globus-gridftp-server 2>/dev/null | grep -v PID | wc -l

echo "<!NULL!>"

exit 0


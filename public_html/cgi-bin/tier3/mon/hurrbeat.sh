#!/bin/bash

ldir=$'/home/ext-jww004'

echo "<!HEARTBEAT_TIME!>"
#TimeStamp

/bin/date +%s

echo "<!HEARTBEAT_HURR!>"
#Can SSH to HURR: 1

/usr/bin/ssh hurr.tamu.edu echo 1 2> /dev/null

echo "<!HEARTBEAT_GLUSTER!>"
#Can Access Gluster Filesystem: 1

/usr/bin/ssh hurr.tamu.edu [ -d /fdata ] && echo "1"

echo "<!HEARTBEAT_DF!>"
#Size of Gluster Filesystem Partition

/usr/bin/ssh hurr.tamu.edu /bin/df -P /fdata 2> /dev/null | grep \/fdata | sed -ne 's/^[^ ]*[ ]*\([0-9]*\).*$/\1/p'

echo "<!HEARTBEAT_DF_QUERY!>"
#DF Query Directory

echo "/bin/df -P /fdata"

echo "<!HEARTBEAT_DU!>"
#Can Run DU on a Small Gluster Directory : 1 

stim=$(/bin/date); /usr/bin/time \
	-f $(/bin/date -d "${stim}" +%s)"\t%E\t%P\t%F\t%W" \
	-o ${ldir}/public_html/OFFLINE/tier3/mon/heartbeat_time.txt \
	/usr/bin/du --max-depth=0 /fdata/hepx/store/temp \
	2> ${ldir}/public_html/OFFLINE/tier3/mon/heartbeat_errors.txt \
	| grep \/fdata | wc -l

echo "<!HEARTBEAT_DU_ERRORS!>"
#Number of Errors

cat ${ldir}/public_html/OFFLINE/tier3/mon/heartbeat_errors.txt | perl -ne \
	'END { print +(0+$errs)."\n" } /Input\/output error/ && $errs++;';

echo "<!HEARTBEAT_DU_TIME!>"
#Stamp	Wall	%CPU	Faults	Swaps

cat ${ldir}/public_html/OFFLINE/tier3/mon/heartbeat_time.txt

echo "<!HEARTBEAT_DU_QUERY!>"
#DU Query Directory

echo "/usr/bin/du --max-depth=0 /fdata/hepx/store/temp"

echo "<!NULL!>"

printf "%s\t%s\n" \
	"$(cat ${ldir}/public_html/OFFLINE/tier3/mon/heartbeat_time.txt)" \
	"$(/bin/date -d "${stim}" +"%A, %d-%b-%Y %H:%M:%S %Z")" \
	2> /dev/null >> ${ldir}/LOGS/time_disk_usage_short.txt

exit 0


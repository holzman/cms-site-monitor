#!/bin/bash

echo "<!CONDORQ_TIME!>"

/bin/date +%s

echo "<!CONDORQ!>"

/apps0/osg-1.2.20/condor/bin/condor_q \
	-format "%-1u " ClusterId \
	-format "%-1u " ProcId \
	-format "%-1s " Owner \
	-format "%-1u " JobUniverse \
	-format "%-1u " JobStatus \
	-format "%-1u " RequestCpus \
	-format "%-1u " ImageSize \
	-format "%-1.0f " RemoteUserCpu \
	-format "%-1.0f " RemoteSysCpu \
	-format "%-1.0f " RemoteWallClockTime \
	-format "%-1.0f " CumulativeSuspensionTime \
	-format "%-1u " QDate \
	-format "%-1u\n" CompletionDate \

echo "<!NULL!>"

exit 0


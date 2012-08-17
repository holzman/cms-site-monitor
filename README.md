
This package includes the initial release version of
the Tier 3 Monitoring package at:

http://collider.physics.tamu.edu/tier3/mon/

A talk on the features of this monitor is available here:

http://www.joelwalker.net/talks/LHC_Monitoring.pdf

A CMS hypernews discussion of this project is available here:

https://hypernews.cern.ch/HyperNews/CMS/get/comp-monitoring/55.html

The lead author of the software is available by email here:

jwalker AT shsu.edu

This package is simply an archive of the main programs
in use at Texas A&M.  As such, it is not yet configured
for easy installation at other sites.  Nevertheless,
you are welcome to explore the software, and make what
use of it you would like, consistent with the GNU
Public License, V3.

http://www.gnu.org/copyleft/gpl.html

In addition to this README file, the distribution
contains two smaller tar-gzipped archives, correpsonding
to the software installed on the main TAMU web server,
and the software installed on the Brazos Tier 3
computing cluster.

In our implementation, the fact that the web server
is housed at a different location than the cluster
means that we must make queries to the cluster
to return information to the main monitor.  These
requests are made over http, and upon receipt jobs
are dispatched to assemble the requested statistics.
A use case that places the monitor web server on the
physical cluster may potentially simplify this
transaction.  

This software is offered without warranty.


#!/usr/bin/perl

use strict;

use FindBin qw($RealBin);

( my $root = $RealBin) =~ s/\/cgi-bin\/tier3\/mon//; my ($opath) = '/OFFLINE/tier3/mon'; my ($hpath) = '/htdocs/tier3/mon';

	# Rounds input number; 2nd argument is digits after decimal; If 3nd argument true, returns string format
sub ROUND { ( my ($base,$rdgt,$text) = ((shift),int((shift)//1),!(!(shift))) )[0] =~ /^(?:\+|-)?\d+(?:\.\d+)?$/ or return;
	( map { $text ? $_.( /(\.)(\d+)$/ ? (!$1 && '.').(q(0)x($rdgt-(length $2))) : '.'.(q(0)x$rdgt) ) : $_ }
		( int ( $base*10**$rdgt + ($base<=>0)*0.5 ) / 10**$rdgt ))[0] }

	# divides 1st argument by 2nd argument, returning undef if denominator is zero
sub SAFE_RATIO { my ($num,$den) = (shift,shift); (return undef) if ($den == 0) or !(defined $num); $num / $den }

	# Adds commas to input number to separate factors of 1000
sub COMMA { ( my ($sign,$nmbr,$dcml) = (shift) =~ /^(\+|-)?(\d+)(\.\d+)?$/ ) or return; my (@nmbr);
	push @nmbr, $1 while $nmbr =~ s/(\d{3})$//; $sign.( join ',', (( length $nmbr ) ? $nmbr : (),( reverse @nmbr ))).$dcml }

	# Reports the arithmetic sum of an input array
sub SUM { my ($sum) = 0; $sum += $_ for @_; $sum }

sub DOT { my ($va,$vb) = map { (@$_==2) && (@{$$_[0]}==@{$$_[1]}) || return; @$_ } [ grep {(ref eq q(ARRAY))} (shift,shift)];
	&SUM( map { $$va[$_]*$$vb[$_] } (0..$#$va)) }

sub AVG { return unless @_; &SUM(@_)/(@_) }

sub STDEV { my ($avg) = &AVG(@_); map { wantarray ? ($_,$avg) : return $_ } ( @_ ? sqrt( abs( &AVG( map {($_ - $avg)**2} @_ ))) : undef ) }

	# Converts unix time in seconds to formated string; If 2nd argument true, uses UTC; 3rd argument is format override
sub DATE_FORMAT { use POSIX(); my ($time,$mode,$tfmt) =
	((shift)//time,( map { !(!$_),(shift)//'%A, %d-%b-%Y %H:%M:%S '.($_?'UTC':'%Z') } (shift) ));
	POSIX::strftime($tfmt, $mode?gmtime($time):localtime($time)) }

	# Converts internal exponent data format to Human readable text; If 2nd argument true, appends 'iB'
sub DATA_FORMAT_EXP_HUMAN { (shift) =~ /^(\d+\.\d+)E(\d+)$/ or return;
	( ROUND($1,1,1)) . ' ' . ${[ q(), qw( K M G T P E Z Y ) ]}[int($2/3)] . ((shift) ? 'iB' : q()) }

	# Converts internal exponent data format to bytes
sub DATA_FORMAT_EXP_BYTES { (shift) =~ /^(\d+\.\d+)E(\d+)$/ or return; ROUND( $1 * 2**(int($2/3)*10 ),0) }

	# Converts Human readable data sizes to internal exponent format
sub DATA_FORMAT_HUMAN_EXP { (shift) =~ /^(\d+(?:\.\d+)?)\s*(|k|m|g|t|p|e|z|y)(:?|b|ib)$/i or return;
	( ROUND($1,3,1)) . 'E' . ${{ q()=>0, q(k)=>3, q(m)=>6, q(g)=>9, q(t)=>12, q(p)=>15, q(e)=>18, q(z)=>21, q(y)=>24 }}{(lc $2)}; }

	# Converts number of bytes to internal exponent format
sub DATA_FORMAT_BYTES_EXP { ( my ($bytes,$expt) = (shift,0))[0] =~ /^\d+$/ or return;
	while ($bytes >= 1024) { $expt++; $bytes /= 1024 }
	( ROUND($bytes,3,1)) . 'E' . 3*$expt; }

	# Converts Human readable data sizes to bytes 
sub DATA_FORMAT_HUMAN_BYTES { DATA_FORMAT_EXP_BYTES ( DATA_FORMAT_HUMAN_EXP(@_) ) }

	# Converts number of bytes to human readable text; If 2nd argument true, appends 'iB'
sub DATA_FORMAT_BYTES_HUMAN { DATA_FORMAT_EXP_HUMAN ( DATA_FORMAT_BYTES_EXP(@_), @_[1] ) }

	# Converts time in seconds to time in HH:MM:SS format; If 2nd argument >=1, that number of decimal hours are used instead
sub TIME_FORMAT_SECONDS_HOURS { ( map { ($$_[1] >= 1) ? &COMMA( &ROUND($$_[0]/3600,(int $$_[1]),1)) :
	join ':', map { ($_<1) ? '00' : ($_<10) ? '0'.$_ : $_ } (int($$_[0]/3600),int(($$_[0]%3600)/60),(($$_[0]%3600)%60)) } [(shift),(shift)])[0] }

	# Converts time in seconds to time in MM:SS format; If 2nd argument >=1, that number of decimal minutes are used instead
sub TIME_FORMAT_SECONDS_MINUTES { ( map { ($$_[1] >= 1) ? &COMMA( &ROUND($$_[0]/60,(int $$_[1]),1)) :
	join ':', map { ($_<1) ? '00' : ($_<10) ? '0'.$_ : $_ } (int($$_[0]/60),int($$_[0]%60)) } [(shift),(shift)])[0] }

	# Converts time in HH:MM:SS or decimal format to seconds "Left to Right"
sub TIME_FORMAT_HOURS_SECONDS { (shift) =~ /^(\d+(?:\.\d*)?)(?::(\d*)(?::(\d*))?)?$/ ? &ROUND($1*3600+$2*60+$3,0) : return }

	# Converts time in [HH]:MM:SS.ff format to seconds "Right to Left"
sub TIME_FORMAT_MINUTES_SECONDS { (shift) =~ /^(?:(?:(\d*):)?(\d*):)?(\d+(?:\.\d*)?)$/ ? &ROUND($1*3600+$2*60+$3,1,1) : return }

sub COLOR_FORMAT_RGB_HSV { # www.easyrgb.com
	my (@rgb) = grep { ($_>=0) && ($_<=1) || return } map {($_/255)} map {(int)} @_[0..2];
	my ($min,$max) = ( sort {($a<=>$b)} @rgb )[0,2]; my ($del) = ($max-$min); my ($mix) = ( grep {($max==$rgb[$_])} (0..2))[0];
	return (0,0,$max) if ($del==0); my (@del) = map { (0.5 + ($max-$_)/(6*$del)) } @rgb;
	(( map {($_-int)} (1+($mix/3)+$del[($mix+2)%3]-$del[($mix+1)%3])),($del/$max),$max); }

sub COLOR_FORMAT_HSV_RGB { # www.easyrgb.com
	my (@hsv) = grep { ($_>=0) && ($_<=1) || return } @_[0..2];
	( map { &ROUND( 255*$hsv[2]*( 1 - $_*$hsv[1] ), 0 )} map {(0,1,$_,(1-$_))} map {(($_)-(int))} (6*$hsv[0]))[
		@{( [0,3,1],[2,0,1],[1,0,3],[1,2,0],[3,1,0],[0,1,2],[0,3,1] )[( int ( 6*$hsv[0] ))] }] }

	# Looks up and reports the Human User Name recorded in /home/websites/collider/OFFLINE/tier3/mon/CONFIG/users.txt
	do { open FHI, $root.$opath.'/CONFIG/users.txt'; my (%users) = map { chomp; /^\s*(\S+)\s+(\S.*?)\s*$/ } <FHI>; close FHI;
sub LOCAL_USER_NAME { ( map { my ($cmsi); ((($cmsi) = /^cms(\d+)$/) ? q(CMS: ) : q() ) . ( $users{$_} // $cmsi // ((shift) ? return : $_ )) }
	grep { defined || return { %users }} (shift))[0] }};

sub LAST_NAME_FIRST { my ($name) = (shift); (( grep { (/[a-z]/) && !(/\.$/) } split /(?:\s+|-)/, $name )[-1] ).(q( )).($name) }

sub TIME_STAMP { use Fcntl qw(:flock :seek); my ($key,$tsp,$osp,%tsp) = ((((shift) =~ /^(\w+)$/)[0]),(((shift) =~ /^(\d+)$/)[0]));
	do { (-f $_) or system ('touch '.$_); ( open FHB, q(+<), $_ ) && ( flock FHB, LOCK_EX ) or return } for ($root.$opath).'/TIMESTAMP/data.txt';
	seek FHB, 0, SEEK_SET; while (<FHB>) { /^(\w+) (\d+)$/ and $tsp{$1} = $2; } return (( scalar { %tsp }),( close FHB ))[0] unless (defined $key);
	$osp = $tsp{$key}; do { $tsp{$key} = $tsp; seek FHB, 0, SEEK_SET; truncate FHB, 0; for (sort keys %tsp) { print FHB $_.q( ).$tsp{$_}."\n"; }} if (defined $tsp);
	close FHB; $osp }

	do { my ($alrt,@alrt,%alrt); ( open FHI, $root.$opath.'/CONFIG/alert.txt' ) && do { do { ((local $_),(my $val)) = @$_;
			m/^alert$/i ? do { push @alrt, ($alrt = (uc $val)); $alrt{$alrt}{alert} = $alrt; } : !(defined $alrt) ? undef :
			m/^active$/i ? do { $alrt{$alrt}{active} = ($val =~ m/^(?:(TRUE|1)|NULL|2)$/i) ? $1 ? 1 : 2 : 0; } :
			m/^text(?:_([1-4]))?$/i ? do { $alrt{$alrt}{text}[0+$1] = $val; } :
			m/^title$/i ? do { $alrt{$alrt}{title} = $val; } :
			m/^email$/i ? do { $alrt{$alrt}{email} = [ grep {(length)} ( split /[,\s]+/, $val )]; } :
			m/^plot$/i ? do { $alrt{$alrt}{plot} = [ map {(lc)} grep { s/\.png$//i; /^[-\w]+$/ } ( split /[,\s]+/, $val )]; } :
			m/^long$/i ? do { $alrt{$alrt}{long} = $val; } : undef ;
			} for ( map { my ($t) = $_; map {[ @$t[2*$_,2*$_+1]]} (0..((@$t/2)-1)) }
		map {[ m/<\s*(\w+)\s*=\s*([^><]*?)\s*>/g ]} grep { s/[\r\n]//g; 1 } ( join '', grep { !/^\s*#/ } (<FHI>))); close FHI; };
sub LOAD_ALERT { my ($key,@vals) = @_; grep { (defined $key) && (return $_); 1 }
	map { 0+(@vals) ? [ @{ $alrt{$_} // (return) }{( map {(lc)} (@vals))} ] : $alrt{$_}} ((defined $key) ? (uc $key) : (@alrt)) }};

sub SUMM_ALERT { ( opendir DHI, $root.$opath.'/ALERTS/CURRENT/' ) || (return);
	scalar { map { /^(\w+)\.txt$/ ? ( (uc $1) => ( pop @{ READ_ALERT($1) // [] })) : () } (readdir DHI) }}

sub READ_ALERT { my ($file,@lines); ( open FHI, '<'.$root.$opath.'/ALERTS/CURRENT/'.( $file = uc ((shift)//(return))).'.txt' ) && do {
		@lines = map { chomp; [ (split /\t/) ]} <FHI>; close FHI; my ($time) = ((time) - 24*3600 + 30);
		open FHO, '>>'.$root.$opath.'/ALERTS/HISTORY/'.($file).'.txt'; while (@lines) { last if ($lines[0][0] >= $time);
			print FHO ( q()).( join "\t", @{ shift @lines } )."\n"; } close FHO; };
	open FHO, '>'.$root.$opath.'/ALERTS/CURRENT/'.($file).'.txt';
	print FHO map { q().( join "\t", @$_ )."\n"; } @lines; close FHO;
#	&STDEV( map { $$_[1] } @lines );
	[ @lines ]; }

	do {	my (%mail) = ( To => q(joelwwalker@gmail.com), From => q(monitor@collider.physics.tamu.edu));
		my (@copy) = ( q(toback@tamu.edu), q(vaikunth@tamu.edu), q(galmes@tamu.edu), q(daniel.cruz@neo.tamu.edu), q(syeager@physics.tamu.edu));
sub MAIL_ALERT { use Mail::Sendmail 0.75; use MIME::QuotedPrint; use MIME::Base64;
	my ($text,$titl,$copy,$atch) = (( "\n".q(This is an automated message from the Tier3 Monitoring System on Collider.)."\n\n" .
		((shift)//(return))."\n\n".q(Threat Level: ).(( qw( NONE LOW MODERATE SEVERE CRITICAL ))[(0..4)[(shift)]//(return)])."\n\n" .
		q(A detailed Alert Summary is available here:)."\n\t".q(http://collider.physics.tamu.edu/tier3/mon/alert.shtml?).((shift)//(return)))."\n",
		(shift), do { my (%copy); do { s/^(?:\+|(-))// && $1 ? ( delete $copy{$_} ) : $copy{$_}++ } for grep {(defined)}
			( @copy, ( map { ( ref eq 'ARRAY' ) ? @$_ : $_ } (shift))); join ', ', ( grep {(length)} sort keys %copy ) },
		[ map { undef ( local $/ ); ( open FHI, $root.$hpath.'/IMAGES/PLOTS/'.($_).'.png' ) && ( binmode FHI ) ?
			[ ($_).'.png', <FHI> ] : () } grep { defined } map { ( ref eq 'ARRAY' ) ? @$_ : $_ } (shift)] );
	$mail{'Subject'} = 'Tier 3 Alert'.((length $titl)?': '.$titl:q()); $mail{'Cc'} = (length $copy) ? $copy : undef;
	$mail{'body'} = (!@$atch) ? $text : do { my ($bdry) = '===='.( time ).'====';
		$mail{'content-type'} = 'multipart/mixed; boundary="'.($bdry).'"';
		'This is a MIME formatted message, which appears to be unsupported by your email client software'."\n" .
		'--'.($bdry)."\n" .
		'Content-Type: text/plain; charset="iso-8859-1"; format=flowed'."\n" .
		'Content-Transfer-Encoding: quoted-printable'."\n" .
		'Content-Disposition: inline'."\n\n" .
		( encode_qp($text))."\n" .
		( join '', ( map { '--'.($bdry)."\n" .
			'Content-Type: image/png; name="'.($$_[0]).'"'."\n" .
			'Content-Transfer-Encoding: base64'."\n" .
			'Content-Disposition: attachment; filename="'.($$_[0]).'"'."\n\n" .
			( encode_base64($$_[1]))."\n" } @$atch )) .
		'--'.($bdry).'--'."\n" };
	sendmail(%mail); # or die $Mail::Sendmail::error
	}};

sub POST_ALERT { ( open FHO, '>>'.$root.$opath.'/ALERTS/CURRENT/'.( uc ((shift)//(return))).'.txt' ) || return;
	print FHO (time)."\t".((0..4)[(shift)]//(return))."\t".(0+!(!(shift))).( join "\t", ((@_?q():()),@_))."\n"; close FHO; }

	do { my (%subc) = ( BR => "\n", TAB => "\t" );
sub ALERT { my ($acde,$alvl,$mail,@pars) = ((uc shift),((0..4)[(shift)]//4),!(!(shift)),@_); my ($time) = ((time) - 4*3600 + 30); my ($actv,$text,$titl,$copy,$plot) =
	@{ &LOAD_ALERT($acde, qw( active text title email plot )) // return }; (($actv) || return); $$text[$_] //= $$text[($_-1)] for (1..4);
	&MAIL_ALERT((( grep {(length)} grep { s/\[(\d+)\]/$pars[($1-1)]/g; s/\[([A-Z]+)\]/$subc{$1}/g; 1 } map { qq($_) } $$text[$alvl])[0] // 'Alert Code: '.$acde),
		(($actv == 2) ? 0 : $alvl),$acde,$titl,$copy,$plot) if ( $mail = ($actv == 2) ||
			(($mail) && ($alvl > 0) && !( grep { ($$_[0] >= $time) && ($$_[1] >= $alvl) && (0+$$_[2]) } @{ &READ_ALERT($acde) // [] })));
	&POST_ALERT($acde,$alvl,$mail,@pars); 1 }};

sub SIZE_IMAGE { use GD::Image; my ($fw,$fh) = ( my $from = GD::Image->newFromPng(
		$root.$hpath.'/IMAGES/PLOTS/'.( my $inam = (shift)).'.png') // return )->getBounds();
	my ($pw,$ph) = grep { ($_ > 0) || return } map { &ROUND($_,0) } map {
		(($$_[0][1])&&!($$_[1][1])) ? ($$_[1][0]*$fw/$fh,$$_[1][0]) :
		(!($$_[0][1])&&($$_[1][1])) ? ($$_[0][0],$$_[0][0]*$fh/$fw) :
		($$_[0][0],$$_[1][0]) } [[(shift)//($fw,1)],[(shift)//($fh,1)]];
	return if (($pw == $fw) && ($ph == $fh));
	my $to = GD::Image->newTrueColor($pw,$ph);
	$to->copyResampled($from,0,0,0,0,$pw,$ph,$fw,$fh);
	open FHO, '>'.$root.$hpath.'/IMAGES/PLOTS/'.$inam.'.png';
	binmode FHO; print FHO $to->png(1); close FHO; }

sub CREATE_THUMB { use GD::Image; my ($fw,$fh) = ( my $from = GD::Image->newFromPng(
		$root.$hpath.'/IMAGES/PLOTS/'.( my $inam = (shift)).'.png') // return )->getBounds();
	my ($pw,$ph) = grep { ($_ > 0) || return } map { &ROUND($_,0) } map {
		(($$_[0][1])&&!($$_[1][1])) ? ($$_[1][0]*$fw/$fh,$$_[1][0]) :
		(!($$_[0][1])&&($$_[1][1])) ? ($$_[0][0],$$_[0][0]*$fh/$fw) :
		($$_[0][0],$$_[1][0]) } [[(shift)//($fw,1)],[(shift)//($fh,1)]];
	if (($pw != $fw) || ($ph != $fh)) { my $tmp = GD::Image->newTrueColor($pw,$ph);
		$tmp->filledRectangle(0,0,$pw,$ph,$tmp->colorAllocate(255,255,255));
		$tmp->copy($from,((&ROUND(abs($pw-$fw)/2,0),0,$fw,$pw)[($pw>$fw)?(0,1,2):(1,0,3)],
			(&ROUND(abs($ph-$fh)/2,0),0,$fh,$ph)[($ph>$fh)?(0,1,2):(1,0,3)])[0,3,1,4,2,5]);
		open FHO, '>'.$root.$hpath.'/IMAGES/PLOTS/'.$inam.'.png';
		binmode FHO; print FHO ( $from = $tmp )->png(1); close FHO; }
	my $to = GD::Image->newTrueColor( my ($tw,$th) = map { &ROUND($_/2,0) } ($pw,$ph));
	$to->copyResampled($from,0,0,0,0,$tw,$th,$pw,$ph);
	open FHO, '>'.$root.$hpath.'/IMAGES/THUMBS/'.$inam.(( my $png = !(!(shift)))?'.png':'.jpg');
	binmode FHO; print FHO ( $png ? $to->png(1) : $to->jpeg(80)); close FHO; }

sub SCORE_PLOT { use GD::Image; my ($fw,$fh) = ( my $from = GD::Image->newFromPng(
	$root.$hpath.'/IMAGES/PLOTS/'.( my $inam = (shift)).'.png') // return )->getBounds();
	my (@scan) = do { my ($scan) = map { (ref eq q(ARRAY)) ? [ map {(int)} @$_ ] : [0,0,$fw,$fh] } (shift);
		map { ( sort {($a<=>$b)} (0,$$scan[$_],($fw,$fh,$fw,$fh)[$_]))[1] } (0..3) }; my (@imod) = map { (
		( map { ($_,int(($scan[2]-$scan[0]-1)/($_))) } int(((($scan[2]-$scan[0])||return)-1)/(($$_[0]-1)||1))||1 ),
		( map { ($_,int(($scan[3]-$scan[1]-1)/($_))) } int(((($scan[3]-$scan[1])||return)-1)/(($$_[1]-1)||1))||1 ),
		) } map { (ref eq q(ARRAY)) ? [ map { ($_>0) ? ($_) : (return) } map {(int)} @$_ ] : [96,48] } (shift);
	my (@scor); for my $y ( reverse map { ($scan[3]-1-($_*$imod[2])) } (0..$imod[3])) { push @scor, [];
		for my $x ( reverse map { ($scan[2]-1-($_*$imod[0])) } (0..$imod[1])) {
			push @{ $scor[$#scor]}, &QUALITY_FORMAT_RGB_SCORE( $from-> rgb( $from-> getPixel($x,$y))) }} (
	[ map {[ 100*(0+@$_)/(1+$imod[1]), ( &STDEV(@$_))[0,1]]} map {[ grep {(defined)} @{ $scor[$_]} ]} (0..$imod[3])],
	[ map {[ 100*(0+@$_)/(1+$imod[3]), ( &STDEV(@$_))[0,1]]} map { my ($icol) = $_; [
		grep {(defined)} map { $$_[$icol] } @scor ]} (0..$imod[1])] ); }

sub QUALITY_FORMAT_RGB_SCORE { my ($scle) = 1.05;
	my (@rgb) = grep { ($_>=0) && ($_<=255) || return } map {(int)} @_[0..2]; (
	map { ($$_[1]<0.2) || ($$_[0]>0.45) && ($$_[0]<0.90) ? undef : (
		map { ( sort {($a<=>$b)} (0,$_,100))[1] } map { &ROUND($_,0) } map { ($scle*($_-50) + 50) }
		map { my ($abc) = ( [+0.0000284571,+0.00176282,-0.00875687], [-0.0000629261,+0.0135049,-0.338643] )[0+($_ >= 0.36)];
			(( -$$abc[1] + sqrt( abs ( $$abc[1]**2 - 4*$$abc[0]*($$abc[2]-$_))))/(2*$$abc[0])) } ($$_[0]-($$_[0]>0.45))) }
		[ &COLOR_FORMAT_RGB_HSV( @rgb ) ])[0] }

sub QUALITY_FORMAT_SCORE_RGB { use POSIX;
	my ($scre) = grep { ($_>=0) && ($_<=100) || return } (shift); &COLOR_FORMAT_HSV_RGB(
	map { (($_ > 1) || ($_ < 0)) ? (($_) - (floor $_)) : $_ } map { $$_[0]*$scre**2 + $$_[1]*$scre + $$_[2] } (
		( [+0.0000284571,+0.00176282,-0.00875687], [-0.0000629261,+0.0135049,-0.338643] )[0+($scre >= 87)],
		( [-0.000205522,-0.000665642,+0.817088], [-0.000111023,+0.0230642,-0.605654] )[0+($scre >= 50)],
		( [-0.000243637,+0.021276,+0.535295], [-0.000122985,+0.00503416,+1.04576] )[0+($scre >= 50)] )) }

sub COLOR_FORMAT_RGB_HEX {
	my (@rgb) = grep { ($_>=0) && ($_<=255) || return } map {(int)} @_[0..2];
	q(#).( join '', map { ${[((0..9),(q(A)..q(F)))]}[$_] } map { ((int ($_/16)), ($_%16)) } @rgb ) }

sub COLOR_FORMAT_HEX_RGB {
	map { my ($hex) = $_; map { 16*(shift @$hex) + (shift @$hex) } (0..2) }
	map { my ($hex) = $_; (@$hex == 6) ? $hex : (@$hex == 3) ? [ map {($_,$_)} @$hex ] : () } 
	map {[ map {( ${{ A => 10, B => 11, C => 12, D => 13, E => 14, F => 15 }}{$_} || (0+$_))} (split //) ]}
	map { m/^#?([0-9A-F]{3,6})$/ } (shift) }

sub IMAGE_SIZE { use GD::Image;
	[( GD::Image->newFromPng(( grep { -f or return } (shift))[0] ) or return )->getBounds() ] }

# rounding issues - ltim vs dtim
# closure for stll tests
sub QUEUE_TABLE { my ($time,$qstt,$mode,$ltim,$stll,$dtim,$ndat) = ( time, [],
	((0,1)[(shift)]//(0)), ( map {( $_ - ($_ % 300))} ((shift)//(time-300))), ( map { (ref eq q(HASH)) ? $_ : {}} (shift)));
	do { my ($jobi,$rusr,$rque,$emod,$ncpu,$memu,$ptim,$rtim,$etim,$ctim) = @$_; my ($tusr) = &LOCAL_USER_NAME($rusr);
		my ($tque,$tmod,$rmod,$tjob) = map {( $$_[0][$rque], $$_[1][$emod], $$_[2][$emod], $$_[3] )} (
			[[ qw(GRID), q(HEPX), q(HEPX ROUTING), q(BGSC), q(BGSC ROUTING) ], [ qw( Queued Running Completed Exiting Held Suspended Waiting Transfer )], [ (0,1,1,1,2,2,0,0)],
				( map { $$_[0].((length $$_[1])?q(:).((q(0))x(4-(length $$_[1]))):q()).($$_[1]) } [$jobi =~ /^(\d+)(?:-(\d+))?$/])[0]],
			[[ q(-), qw( Standard Pipe Linda PVM Vanilla PVMD Scheduler MPI Grid Java Parallel Local VM ), q(-)],
				[ qw( Queued Idle Running Removed Completed Held Transfer )], [ (0,0,1,1,1,2,0)],
				( join q(:), map { ((q(0))x(3-(length $_))).($_) } ($jobi =~ /^(\d+):(\d+)$/)) ],
		)[$mode]; my ($kusr) = &LAST_NAME_FIRST($tusr); my ($qtim) = ( sort { $a <=> $b } (0,(($ctim || $dtim) - $etim - $rtim )))[1];
		# 0: $$stll{$tusr}++ if (($rmod == 2) || (($rmod == 0) && ($qtim >= 3600*((12,3,12)[$rque])) && (($rtim/$qtim) < 0.25)));
		# 1: $$stll{$tusr}++ if (($rmod == 2) || (($rmod == 0) && ($qtim >= 3*3600) && (($rtim/$qtim) < 0.25)));
		$$stll{$tusr}++ if (($rmod == 2) && !(($mode == 0) && ((1,0,0,1,1)[$rque])));
		for my $i (0..2) { my ($path) = $$qstt[$i] //= [[undef,{},{},[],(undef)[0..5]],{}]; for (
			([$kusr,$tusr],[$rque,$tque],[$emod,$tmod])[$i],[$jobi,$tjob],undef) {
			$$path[0][1]{$tusr}++; $$path[0][2]{$tque}++; $$path[0][3][$rmod]++; $$path[0][4]++;
			$$path[0][5] += $ncpu; $$path[0][6] += $memu; $$path[0][7] += $ptim; $$path[0][8] += $rtim; $$path[0][9] += $qtim;
			$path = ${ $$path[1]}{$$_[0]} //= [[$$_[1],{},{},[],(undef)[0..5]],{}] if (defined); } @{ $$path[0]}[3,4] = ($rmod,$tmod); }}
	for map { ( open FHI, $_ ) ? @{ (( grep { $dtim = $ltim; 1 } [ map { chomp; [ split "\t" ]} <FHI> ]), ( close FHI ))[0] } : () }
		grep { ( -f ) || ($ndat++) } ($root.$opath).'/LOGS/'.(( qw( QSTAT CONDORQ))[$mode]).'_DATA/'.($ltim).'.dat';
	my (@qnam) = @{ ([ qw( qstat QStat Queue TORQUE)], [ qw( condorq CondorQ Universe Condor)])[$mode] }; my $tble = q();
	$tble .= '<DIV id="'.($qnam[0]).'_data_anchor" style="z-index:0; display:block; position:static; height:auto; width:826px; margin:0px 0px; padding:0px; text-align:center; overflow:hidden;">'."\n";
	$tble .= "\t".'<table class="mon_default" style="width:826px; height:auto;">'."\n";
	$tble .= "\t\t".'<tr class="mon_default" style="display:block; color:black; background-color:#FFFFFF;">'."\n";

	$tble .= "\t\t\t".'<td colspan="5" class="mon_default" style="width:810px; height:16px;">'."\n";
	$tble .= "\t\t\t\t".'<DIV style="float:left; clear:none; width:30%; margin:0px; padding:0px; text-align:center;">' .
		(( join '&nbsp;|&nbsp;', map { '<a href="wayback.shtml?'.(( qw( qstat condorq))[$mode]).'_'.($ltim+$$_[1]).'" class="mon_default" target="WAYBACK">'.($$_[0]).'</a>' } ([q(Month),-30*24*3600],[q(Week),-7*24*3600],[q(Day),-24*3600],[q(Hour),-3600],[q(Back),-300])).q(&nbsp;<<)).'</DIV>'."\n";
	$tble .= "\t\t\t\t".'<DIV style="float:left; clear:none; width:40%; margin:0px; padding:0px; text-align:center;">'.($qnam[3]).' Queue Job Status ( '.( &DATE_FORMAT(($dtim//$ltim),1,q(%Y-%m-%d %R UTC))).' )</DIV>'."\n";
	$tble .= "\t\t\t\t".'<DIV style="float:left; clear:none; width:30%; margin:0px; padding:0px; text-align:center;">' .
		(( map { (length) ? q(>>&nbsp;).($_) : q() } ( join '&nbsp;|&nbsp;', map { '<a href="wayback.shtml?'.(( qw( qstat condorq))[$mode]).'_'.($ltim+$$_[1]).'" class="mon_default" target="WAYBACK">'.($$_[0]).'</a>' } ( grep {($$_[1] <= ($time - $ltim))} ([q(Next),+300],[q(Hour),+3600],[q(Day),+24*3600],[q(Week),+7*24*3600],[q(Month),+30*24*3600]))))[0]).'</DIV>'."\n";
	$tble .= "\t\t\t".'</td>'."\n";
	$tble .= "\t\t".'</tr>'."\n"; for my $i (0..2) {
		$tble .= "\t\t".'<tr id="'.($qnam[0]).'_data_sort_'.$i.'" class="mon_default" style="display:'.(( qw( block none none ))[$i]).'; color:black; background-color:#FFFFFF;">'."\n";
		$tble .= "\t\t\t".'<td colspan="5" class="mon_default" style="width:820px; height:auto; padding:0px; border-width:0px;">'."\n";
		$tble .= "\t\t\t\t".'<table class="mon_default" style="width:820px; height:auto; border-width:0px;">'."\n";
		$tble .= "\t\t\t\t\t".'<tr class="mon_default" style="display:block; color:black; background-color:#20B2AA;">'."\n";
		$tble .= join q(), (
			"\t\t\t\t\t\t".'<td class="mon_default" style="width:146px; height:16px;">User Name</td>'."\n",
			"\t\t\t\t\t\t".'<td class="mon_default" style="width:92px; height:16px;">'.($qnam[2]).'</td>'."\n",
			"\t\t\t\t\t\t".'<td class="mon_default" style="width:92px; height:16px;">Run Status</td>'."\n",
			)[@{ ([0,1,2],[1,2,0],[2,0,1])[$i]}];
		$tble .= "\t\t\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px;">Processors</td>'."\n";
		$tble .= "\t\t\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px;">Memory</td>'."\n";
		$tble .= "\t\t\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px;">CPU Hours</td>'."\n";
		$tble .= "\t\t\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px;">Run Hours</td>'."\n";
		$tble .= "\t\t\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px;">Queue Hours</td>'."\n";
		$tble .= "\t\t\t\t\t".'</tr>'."\n";
		my ($j) = 0; for ( sort ${( \sub { $a <=> $b }, \sub { $a cmp $b } )[0+($i==0)]} keys %{ $$qstt[$i][1]}) { my ($path) = ${ $$qstt[$i][1]}{$_};
			$tble .= "\t\t\t\t\t".'<tr class="mon_default" id="'.($qnam[0]).'_data_select_'.$i.'_'.$j.'" style="display:block; color:black; background-color:#'.(($$path[0][3][2]) ? q(E62E2E) : ($$path[0][3][0]) ? q(F2D230) : q(3DCC3D)).'; cursor:pointer;" onClick="javascript:'.($qnam[1]).'DataToggle('.($i).','.($j).');" onMouseOver="javascript:this.style.backgroundColor=\'#3BB9FF\';" onMouseOut="javascript:this.style.backgroundColor=\'#'.(($$path[0][3][2]) ? q(E62E2E) : ($$path[0][3][0]) ? q(F2D230) : q(3DCC3D)).'\';">'."\n";
			$tble .= "\t\t\t\t\t\t".'<td class="mon_default" style="width:'.(( qw( 146 92 92 ))[$i]).'px; height:16px; color:inherit; background-color:transparent;">'."\n";
			$tble .= "\t\t\t\t\t\t\t".'<DIV style="position:relative; left:0px; top:0px; width:'.(( qw( 146 92 92 ))[$i]).'px; height:16px; padding:0px; display:block;">'.($$path[0][0]//q(-))."\n";
			$tble .= "\t\t\t\t\t\t\t\t".'<DIV id="'.($qnam[0]).'_data_indicator_'.($i).'_'.($j).'_0" style="position:absolute; top:-2px; left:0px; display:block;">&rarr;</DIV>'."\n";
			$tble .= "\t\t\t\t\t\t\t\t".'<DIV id="'.($qnam[0]).'_data_indicator_'.($i).'_'.($j).'_1" style="position:absolute; top:-2px; left:0px; display:none;">&darr;</DIV>'."\n";
			$tble .= "\t\t\t\t\t\t\t".'</DIV>'."\n";
			$tble .= "\t\t\t\t\t\t".'</td>'."\n";
			$tble .= join q(), (
				"\t\t\t\t\t\t".'<td class="mon_default" style="width:146px; height:16px; color:inherit; background-color:transparent;">'.(( map { (@$_>1) ? q(MIXED) : $$_[0]//q(-) } [ keys %{ $$path[0][1]}])[0]).(($i==2) && ' ('.(&COMMA($$path[0][4])//q(-)).')').'</td>'."\n",
				"\t\t\t\t\t\t".'<td class="mon_default" style="width:92px; height:16px; color:inherit; background-color:transparent;">'.(( map { (@$_>1) ? q(MIXED) : $$_[0]//q(-) } [ keys %{ $$path[0][2]}])[0]).'</td>'."\n",
				"\t\t\t\t\t\t".'<td class="mon_default" style="width:92px; height:16px; color:inherit; background-color:transparent;">'.( join ' / ', &COMMA($$path[0][3][1]//0), &COMMA($$path[0][4])).'</td>'."\n",
				)[@{ ([1,2],[2,0],[0,1])[$i]}];
			$tble .= "\t\t\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px; color:inherit; background-color:transparent;">'.( &COMMA($$path[0][5])).'</td>'."\n";
			$tble .= "\t\t\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px; color:inherit; background-color:transparent;">'.( &DATA_FORMAT_BYTES_HUMAN($$path[0][6],1)).'</td>'."\n";
			$tble .= "\t\t\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px; color:inherit; background-color:transparent;">'.( &TIME_FORMAT_SECONDS_HOURS($$path[0][7],1)).'</td>'."\n";
			$tble .= "\t\t\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px; color:inherit; background-color:transparent;">'.( &TIME_FORMAT_SECONDS_HOURS($$path[0][8],1)).'</td>'."\n";
			$tble .= "\t\t\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px; color:inherit; background-color:transparent;">'.( &TIME_FORMAT_SECONDS_HOURS($$path[0][9],1)).'</td>'."\n";
			$tble .= "\t\t\t\t\t".'</tr>'."\n";
			my ($k) = 0; for ( map {( shift @$_ )} sort { ($$a[1]<=>$$b[1]) || ($$a[2]<=>$$b[2]) }
				map {[ $_, /^(\d+)(?:(?:|-)(\d+))?$/ ]} keys %{ $$path[1]} ) { my ($path) = ${ $$path[1]}{$_};
				$tble .= "\t\t\t\t\t".'<tr class="mon_default" id="'.($qnam[0]).'_data_element_'.($i).'_'.($j).'_'.($k).'" style="display:none; color:black; background-color:#'.(( qw( F5F384 F5E964 CBF7D2 9AE3A5 F5D0D0 F7B0B0 ))[(2*$$path[0][3])+($k%2)]).';">'."\n";
				$tble .= "\t\t\t\t\t\t".'<td class="mon_default" style="position:relative; left:0px; top:0px; width:'.(( qw( 146 92 92 ))[$i]).'px; height:16px; color:inherit; background-color:transparent;">'.(( '<a href="http://brazos.tamu.edu/cgi-bin/jobstat.pl?'.($_).'" class="mon_default" target="NEW">', q())[$mode]).($$path[0][0]).( ('</a>')[$mode]).'</td>'."\n";
				$tble .= join q(), (
					"\t\t\t\t\t\t".'<td class="mon_default" style="width:146px; height:16px; color:inherit; background-color:transparent;">'.(( map { $$_[0]//q(-) } [ keys %{ $$path[0][1]}])[0]).'</td>'."\n",
					"\t\t\t\t\t\t".'<td class="mon_default" style="width:92px; height:16px; color:inherit; background-color:transparent;">'.(( map { $$_[0]//q(-) } [ keys %{ $$path[0][2]}])[0]).'</td>'."\n",
					"\t\t\t\t\t\t".'<td class="mon_default" style="width:92px; height:16px; color:inherit; background-color:transparent;">'.($$path[0][4]//q(-)).'</td>'."\n",
					)[@{ ([1,2],[2,0],[0,1])[$i]}];
				$tble .= "\t\t\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px; color:inherit; background-color:transparent;">'.( &COMMA($$path[0][5])).'</td>'."\n";
				$tble .= "\t\t\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px; color:inherit; background-color:transparent;">'.( &DATA_FORMAT_BYTES_HUMAN($$path[0][6],1)).'</td>'."\n";
				$tble .= "\t\t\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px; color:inherit; background-color:transparent;">'.( &TIME_FORMAT_SECONDS_HOURS($$path[0][7],2)).'</td>'."\n";
				$tble .= "\t\t\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px; color:inherit; background-color:transparent;">'.( &TIME_FORMAT_SECONDS_HOURS($$path[0][8],2)).'</td>'."\n";
				$tble .= "\t\t\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px; color:inherit; background-color:transparent;">'.( &TIME_FORMAT_SECONDS_HOURS($$path[0][9],2)).'</td>'."\n";
				$tble .= "\t\t\t\t\t".'</tr>'."\n"; } continue { $k++; }
			} continue { $j++; }
		$tble .= "\t\t\t\t\t".'<tr class="mon_default" style="display:block; color:black; background-color:#20B2AA;">'."\n";
		$tble .= "\t\t\t\t\t\t".'<td class="mon_default" style="width:'.(( qw( 146 92 92 ))[$i]).'px; height:16px;">Totals</td>'."\n";
		$tble .= join q(), (
			"\t\t\t\t\t\t".'<td class="mon_default" style="width:146px; height:16px; color:inherit; background-color:transparent;">'.(( map { (@$_>1) ? q(MIXED) : $$_[0]//q(-) } [ keys %{ $$qstt[$i][0][1]}])[0]).(($i==2) && ' ('.(&COMMA($$qstt[$i][0][4])//q(-)).')').'</td>'."\n",
			"\t\t\t\t\t\t".'<td class="mon_default" style="width:92px; height:16px; color:inherit; background-color:transparent;">'.(( map { (@$_>1) ? q(MIXED) : $$_[0]//q(-) } [ keys %{ $$qstt[$i][0][2]}])[0]).'</td>'."\n",
			"\t\t\t\t\t\t".'<td class="mon_default" style="width:92px; height:16px; color:inherit; background-color:transparent;">'.( join ' / ', ((defined $$qstt[$i][0][4]) ? ( &COMMA($$qstt[$i][0][3][1]//0), &COMMA($$qstt[$i][0][4])) : ( q(-), q(-)))).'</td>'."\n",
			)[@{ ([1,2],[2,0],[0,1])[$i]}];
		$tble .= "\t\t\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px; color:inherit; background-color:transparent;">'.( &COMMA($$qstt[$i][0][5])//q(-)).'</td>'."\n";
		$tble .= "\t\t\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px; color:inherit; background-color:transparent;">'.((defined $$qstt[$i][0][6]) ? &DATA_FORMAT_BYTES_HUMAN($$qstt[$i][0][6],1) : q(-)).'</td>'."\n";
		$tble .= "\t\t\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px; color:inherit; background-color:transparent;">'.((defined $$qstt[$i][0][7]) ? &TIME_FORMAT_SECONDS_HOURS($$qstt[$i][0][7],1) : q(-)).'</td>'."\n";
		$tble .= "\t\t\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px; color:inherit; background-color:transparent;">'.((defined $$qstt[$i][0][8]) ? &TIME_FORMAT_SECONDS_HOURS($$qstt[$i][0][8],1) : q(-)).'</td>'."\n";
		$tble .= "\t\t\t\t\t\t".'<td class="mon_default" style="width:82px; height:16px; color:inherit; background-color:transparent;">'.((defined $$qstt[$i][0][9]) ? &TIME_FORMAT_SECONDS_HOURS($$qstt[$i][0][9],1) : q(-)).'</td>'."\n";
		$tble .= "\t\t\t\t\t".'</tr>'."\n";
		$tble .= "\t\t\t\t".'</table>'."\n";
		$tble .= "\t\t\t".'</td>'."\n";
		$tble .= "\t\t".'</tr>'."\n"; }
	$tble .= "\t\t".'<tr class="mon_default" style="display:block; color:black; background-color:#FFFFFF;">'."\n";
	$tble .= "\t\t\t".'<td class="mon_default" style="width:350px; height:16px; color:inherit; background-color:#FFFFFF;' .
		(( keys %{ $$qstt[0][1]}) ? ' cursor:pointer;" onClick="javascript:'.($qnam[1]).'DataToggleAll();" onMouseOver="javascript:this.style.backgroundColor=\'#3BB9FF\';" onMouseOut="javascript:this.style.backgroundColor=\'#FFFFFF\';">' : '">' ) .
		(( keys %{ $$qstt[0][1]}) ? '&uarr; Click to Expand or Collapse Table' : 'No Jobs Queued' ) . '</td>'."\n";
	$tble .= "\t\t\t".'<td class="mon_default" style="width:174px; height:16px;">Select Sorting By &rarr;</td>'."\n";
	$tble .= "\t\t\t".'<td id="'.($qnam[0]).'_data_sort_select_user" class="mon_default" style="width:82px; height:16px; color:black; background-color:#3BB9FF; cursor:pointer;" onClick="javascript:'.($qnam[1]).'DataSortSelect(0);" onMouseOver="javascript:this.style.backgroundColor=\'#3BB9FF\';" onMouseOut="javascript:if('.($qnam[1]).'DataSortIndex!=0)this.style.backgroundColor=\'#FFFFFF\';">User</td>'."\n";
	$tble .= "\t\t\t".'<td id="'.($qnam[0]).'_data_sort_select_queue" class="mon_default" style="width:82px; height:16px; color:black; background-color:#FFFFFF; cursor:pointer;" onClick="javascript:'.($qnam[1]).'DataSortSelect(1);" onMouseOver="javascript:this.style.backgroundColor=\'#3BB9FF\';" onMouseOut="javascript:if('.($qnam[1]).'DataSortIndex!=1)this.style.backgroundColor=\'#FFFFFF\';">'.($qnam[2]).'</td>'."\n";
	$tble .= "\t\t\t".'<td id="'.($qnam[0]).'_data_sort_select_status" class="mon_default" style="width:82px; height:16px; color:black; background-color:#FFFFFF; cursor:pointer;" onClick="javascript:'.($qnam[1]).'DataSortSelect(2);" onMouseOver="javascript:this.style.backgroundColor=\'#3BB9FF\';" onMouseOut="javascript:if('.($qnam[1]).'DataSortIndex!=2)this.style.backgroundColor=\'#FFFFFF\';">Status</td>'."\n";
	$tble .= "\t\t".'</tr>'."\n";
	$tble .= "\t\t".'<tr class="mon_default" style="display:block; color:white; background-color:#E62E2E;">'."\n" .
		"\t\t\t".'<td colspan="5" class="mon_default" style="width:810px; height:16px;">No Data Download</td>'."\n" .
		"\t\t".'</tr>'."\n" if ($ndat);
	$tble .= "\t".'</table>'."\n";
	$tble .= '</DIV>'."\n";
	$tble }

1;


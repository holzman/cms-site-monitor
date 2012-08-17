
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


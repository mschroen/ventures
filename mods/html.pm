#!perl -w
package html; #V 2014jan06 init template, goon prints to next marker 
no warnings 'uninitialized';
use strict;
use F;

my @part = ("content-type:text/html\n\n");
my @partname = ();
my $id = 0;

sub new
{
	my $c = shift;
	my $s = {};
	$s->{'mode'} = 'html';
	my @a = ('dummy');
	my @b = ('dummy');
	$s->{'ID'} = \@a;
	$s->{'Clip'} = \@b;
	$s->{'search'} = $_[0] ? 1:0;
	bless $s, $c;
	return $s;
}

sub init # file
{
	my $s = shift;
	my $k = 0;
	open T, shift or print "Open template fails\n";
	while (<T>) {
		if (/^(.*)<\!--([A-Z]+)-->(.*)$/) {
			$part[$k] .= $1;
			$partname[$k] = $2;
			$part[++$k] = $3; }
		else {
			$part[$k] .= $_; }}
	close T;
}

sub goon { my $s = shift; print shift @part; return shift @partname; }

sub navitem { # chapterdir number chaptername CHAPTER
	my $s = shift; return '<li><a href="index.pl?chapter='.$_[0].'"'.($_[3]eq$_[0]?' class="active"':'').'><span>'.$_[1].'.</span> '.($_[2]?$_[2]: F::filename2nice($_[0])).'</a></li>'; }

sub searchhead {
	my $s = shift;
	return '<div class="info">Searching: <code>'.shift.'</code></div>'
	.'<style>h1,h2,h3,h4,h5,h6,h7 { margin:0;padding:1px; font-size:16px; }</style>'; }

sub appendix { my $s = shift; return '<div class="appendix">'
	.'<span class="sans">Appendix:</span> '.shift.'</div>' if $_[0]; }

sub heading {
	my $s = shift;
	my $h = ($_[2] >=1 and $_[2] <=6) ? $_[2] : 6;
	#my $headid = $_[0].$_[3]; $headid=~s/\./_/g;
	my $r = '<h'.$h.' id="head_'.$s->ID.'">';
	$r .= '<a href="index.pl#head_'.$s->ID.'">' if $s->{'search'};
	$r .= '<span class="count">'.$_[0].'</span> <span id="head_name_'.$s->ID.'">'.F::filename2nice($_[1]).'</span>';
	$r .= '<span class="head_save" id="head_save_'.$s->ID.'" style="display: none;">'
		.'<a href="javascript:savehead('.$s->ID.')" title="Save heading" class="edit" id="head_edit_save_'.$s->ID.'">Save</a>'
		.'<a href="javascript:rename_cancel('.$s->ID.')" title="Cancel rename" class="cancel">&times;</a>'
		.'</span><span class="head_edit" id="head_edit_'.$s->ID.'" style="display: inline-block;">'
		.'<a href="javascript:rename('.$s->ID.')" title="Rename" class="edit">&#9998;</a>'
		.'<a href="javascript:cut('.$s->ID.')" title="Cut to clipboard" class="cut" id="head_edit_cut_'.$s->ID.'">&#9986;</a>'
		.'<a href="javascript:remove('.$s->ID.')" title="Delete to trash" class="delete" id="head_edit_delete_'.$s->ID.'">&times;</a>'
		.'</span>' if not $s->{'search'};
	$r .= '</a>' if $s->{'search'};
	return $r.'</h'.$h.'>'; }

sub tocitem_start {
	my $s = shift; #my $headid = $_[0].$_[2]; $headid=~s/\./_/g;
	return '<div id="toc_item_'.$s->ID.'"><a href="#head_'.$s->ID.'">'
		.'<span class="count">'.$_[0].'</span> <span id="toc_name_'.$s->ID.'">'
		.F::filename2nice($_[1]).'</span></a>'; }
sub tocitem_end { return '</div>'; }

sub LINK { my $s = shift;
	my $x = shift; my $last = $1 if $x=~s/([\.\,])$//; 
	if ($x=~/^[a-z]:/i) { $x=~s/\\/\//g; $x='file:///'.$x; }
	my $y=$x; $y=~s/^(file|https?):\/+//;
	return '<a href="'.$x.'" title="'.$x.'" class="LINK">'.$y.'</a>'.$last; }
sub RQ   { my $s = shift; return '<div class="RQ"><span class="sans">RQ</span> '.shift.' </div>'; }
sub TODO { my $s = shift; return '<div class="TODO"><span class="sans">TODO</span> '.shift.' </div>'; }
sub ASK { my $s = shift; return '<div class="ASK"><span class="sans">ASK</span> '.shift.' </div>'; }
sub AHA { my $s = shift; return '<div class="AHA"><span class="sans">AHA</span> '.shift.' </div>'; }
sub CITE { my $s = shift;
	$s->{'cite'}++;
	return '<div class="CITE"><span class="sans">"</span>'; }
sub REF {
	my $s = shift; 
	my $x = shift;
	my $u = F::uniq;
	my $sep = index($x,',');
	my $r = '<div class="REF"><span class="sans">REF</span><span class="clickfeld" onclick="toggle(\'REF'.$u.'\',\'inline-block\')">'
		.substr($x,0,$sep<0?length$x:$sep).'</span><span id="REF'.$u.'" class="extend">'.substr($x,$sep<0?0:$sep).'</span></div>';
	if ($s->{'cite'}) { $r = "\n".$r.'</div>'; $s->{'cite'}--; }
	return $r;
 }
sub FILE {
	my $s = shift; 
	my $x = $_[1];
	if ($x) {
		return '' if not -T $_[0];
		open (my $F, $_[0]) or print $s->error('Unable to read file: '.$!);
		while (<$F>) { if (/$x/i) { $s = ''; last; }}	close $F;
		return '' if $x ne ''; }
	my ($a, $b) = split /\./, substr($_[0], rindex($_[0], '/')+1);
	return '<div class="FILE"><span class="sans">'.($b?uc($b):'FILE').'</span>'
	.'<a href="'.$_[0].'" title="'.$_[0].'">'.F::filename2nice($a).'</a></div>'; }
sub IMG {
	my $s = shift;
	my ($path, $caption, $span) = @_;
	my $name = substr $path, rindex($path, '/')+1;
	my $options = '';
	$options = 'width: 40%;' if $name=~/\.svg$/i;
	$options = 'width: 90%;' if $span;
	return '<div style="text-align: center"><img src="'.$path.'" style="margin: 0 auto; width: 50%; max-width: 80%;'.$options.'">'
		.'<br>'.$caption.'</div>'; }
sub FLAG {
	my $s = shift; return '<span class="flag" id="FLAG_'.$_[0].'" title="FLAG '.$_[0].'">&diams;</span>'; }
sub SEE {
	my $s = shift; return '<a href="index.pl#FLAG_'.$_[0].'" class="flag" title="go to FLAG '.$_[0].'">&#8599;</a>'; }	
sub LIST {
	my $s = shift; my $x = shift;
	#$x =~ s/(^|\n)-\s+([^\n]+)\n/<li>$1<\/li>/mgs;
	return '<ul>'.$x.'</ul>'; }	
	
sub content # file, search, unformatted
{
	my $s = shift; 
	$s->{'cite'} = 0;
	my ($r, $raw) = '';
	my $path = substr $_[0], 0, rindex($_[0], '/')+1;
	open (my $F, shift) or print $s->error('Unable to read content: '.$!);
	my $search = shift;
	
	my ($list,$table) = 0;
	while (<$F>)
	{
		next if $search and not /$search/i;
		$raw .= $_;
		s/FILE\s+(.+)(\s*)$/$s->FILE($path.$1).$2/ge;
		s/TODO\s+(.+)(\s*)$/$s->TODO($1).$2/ge;
		s/ASK\s+(.+)(\s*)$/$s->ASK($1).$2/ge;
		s/(([a-z]|https?):(\\|\/|\/\/)\S+)/$s->LINK($1)/gei;
		s/CITE(\s+)/$s->CITE.$1/ge;
		s/\(REF\s+([^\)]+)\)/$s->REF($1)/ge;
		s/REF\s+(.+)(\s*)$/$s->REF($1).$2/ge;
		s/AHA\s+(.+)(\s*)$/$s->AHA($1).$2/ge;
		s/RQ\s+(.+)(\s*)$/$s->RQ($1).$2/ge;
		s/IMG\s+([^ ]+)(\s+.+)?(\s*)$/$s->IMG($path.$1,$2,0).$3/ge;
		s/IMG\*\s+([^ ]+)(\s+.+)?(\s*)$/$s->IMG($path.$1,$2,1).$3/ge;
		s/FLAG\s+(\w+)/$s->FLAG($1).$2/ge;
		s/SEE\s+(\w+)/$s->SEE($1).$2/ge;
		s/(^|\s)\*([^\*]+)\*(\s|\.|\,|$)/$1<b>$2<\/b>$3/g;
		s/CODE\s+(.+)(\s*)$/<code>$1<\/code>$2/g;
		s/AUTHORS\s+(.+)(\s*)$/<div class=\"authors sans\">by $1<\/div>$2/g;
		
		if (/(^|\n)-\s+(.+)$/) { $_ = '<li>'.$2.'</li>'; $r .= '<ul>' if not $list;	$list++; }
		elsif ($list) {	$_ = '</ul>'.$_; $list = 0; }
		
		if (/(^|\n)\|\s+(.+)\|\s+$/) { $_ = '<tr><td>'.$2.'</td></tr>'; s/\|/<\/td><td>/g; $r .= '<table>' if not $table; $table++; }
		elsif ($table) { $_ = '</table>'.$_; $table = 0; }
		
		$r .= $_;
	}
	if ($list) { $r .= "\n".'</ul>'; }
	if ($table) { $r .= '</table>'.$_; }
	close $F;
	return $r if $_[0];
	my $lines =()= $raw =~ /\n/g;
	$r = '<div class="content" id="content_'.$s->ID.'" style="display: block;'.($search?'':'margin-top:0;').'">'.$r.'</div>' if $r or not $search;
	$r = '<div class="contenttable">'
		.$r
		.'<div class="contentedit tex2jax_ignore" id="contentedit_'.$s->ID.'" contenteditable style="display: none;"></div>'
		.'<div class="sans editcontent">
		<a href="javascript:editcontent('.$s->ID.')" id="editcontent_'.$s->ID.'" class="editcontent_edit" title="Edit" style="display:block">&#9998;</a>
		<a href="javascript:canceledit('.$s->ID.')" id="canceledit_'.$s->ID.'" class="editcontent_cancel" title="Cancel">&times;</a>
		<a href="javascript:savecontent('.$s->ID.')" id="savecontent_'.$s->ID.'" class="editcontent_save">Save</a></div>'
		.'</div>' if not $search;
	return $r;
}

sub error { return '<div class="error">'.shift.'</div>'; }
sub ID
{
	my $s = shift;
	push @{$s->{'ID'}}, shift if @_;
	return $#{$s->{'ID'}};
}

sub IDS
{
	my $s = shift;
	return 'var IDS = new Array('.join(',',map {'"'.$_.'"'} @{$s->{'ID'}}).');'."\n";
}

sub section_start { # path name no-addsection indexpos
	my $s = shift;
	return '<section id="section_'.$s->ID($_[0].'/'.$_[1]).'">'.($_[2]?'':$s->addsection(shift.'/',$_[2])); }

sub section_end { # path no-addsection indexpos
	my $s = shift;
	return ''.($_[1]?'':$s->addsection(shift.'/',$_[1]+1)).'</section><!--'.$s->ID.'-->'; }

sub addsection
{
	my $s = shift; return '' if $s->{'search'};
	my $p = shift;
	my $u = F::uniq;
	my $pn = $p=~/chapter\/?$/ ? 'New Venture' : substr($p, index($p,'/')+1); $pn =~ s/\// \/ /g;
	return '<div id="addsection_'.$u.'_'.$_[0].'">'
		.'<a class="sans addsection" href="javascript:addsection('.$u.','.$_[0].',\''.$p.'\')">'
		.$pn.' <span>+</span></a></div>';
}

sub title
{
	my $s = shift; 
	return '<div class="content sans title">'.shift.'</div>' if @_; 
	return '' if not -f 'chapter/title.txt';
	my $r = '';
	open my $F, 'chapter/title.txt';
	while (<$F>)
	{
		s/(https?:\/\/\S+)/$s->LINK($1)/ge;
		$r .= $_;
	}
	close $F;
	return $r ? '<div class="content sans title">'.$r.'</div>' : '';
}

sub cutted  { return '<div class="info">Moved the section to <code>clipboard/<b>'.shift.'</b></code></div>'; }
sub deleted { return '<div class="info">Moved the section to <code>trash/<b>'.shift.'</b></code><br>Please erase manually.</div>'; }

sub clipboard_section_start { # no margin
	my $s = shift;
	if ($_[0] eq 'clipboard')
	{
		$s->{'opath'} = '(unknown)';
		$s->{'otime'} = (stat($_[0].'/'.$_[1]))[9];
		if (-f $_[0].'/'.$_[1].'/.origin')
		{
			open my $F, $_[0].'/'.$_[1].'/.origin';
			($s->{'opath'}, $s->{'$otime'}) = <$F>;
			close $F;
			chomp $s->{'opath'};
		}
	}
	#$s->Clip($s->{'opath'});
	return '<section id="section_'.$s->ID($_[0].'/'.$_[1]).'" '.($_[2]?'':'style="margin-left:2em"').'>'; }
	
	
sub clipboard_heading
{
	my $s = shift;
	my $h = $_[1] == 1 ? 2 : 6;

	my $r = '<h'.$h.' id="head_'.$s->ID.'"><span id="head_name_'.$s->ID.'">'.F::filename2nice($_[0]).'</span>';
	
	if ($_[1] == 1)
	{
		if ($s->{'opath'} ne '(unknown)')
		{
			$r .= '<span class="head_edit" id="head_edit_'.$s->ID.'" style="display: inline-block;">'
			.'<a href="javascript:restore('.$s->ID.',1,0)" title="Restore" class="edit" id="head_edit_restore_'.$s->ID.'">&#8635;</a>'
			.'</span>';
		}
		my @l = localtime $s->{'otime'};
		$r .= '<div class="headsubinfo">'
		.sprintf("%4s-%02s-%02s, %02s:%02s:%02s", $l[5]+1900,$l[4]+1,$l[3],$l[2],$l[1],$l[0])
		.' from <code>'.$s->{'opath'}.'</code></div>';
	}
	return $r.'</h'.$h.'>';
}

sub newmenu # id ipos dir
{
	my $s = shift;
	my $a = '<div class="addsection_menu sans" id="addsection_menu_'.$_[0].'"><form method="POST" action="add.pl">'
	.'<table style="width:100%; text-align: center;"><tr><td><input id="addsection_input_'.$_[0].'" name="newsectionname" class="sans" /></td>'
	.'<td style="width: 100px"><button type="submit" class="sans">Create</button></td></tr></table>'
	.'<input type="hidden" name="ipos" value="'.$_[1].'"/><input type="hidden" name="dir" value="'.$_[2].'"/></form>';
	my $b = '';
	mkdir 'clipboard' if not -d 'clipboard';
	opendir my $D, 'clipboard/';
	while (my $d = readdir $D)
	{
		next if not -d 'clipboard/'.$d or $d=~/^\.+$/;
		my @origin = ();
		if (-f 'clipboard/'.$d.'/.origin')
		{
			open (my $F, 'clipboard/'.$d.'/.origin') or die $!; # RPATH TIME NICENAME INDEXPOS
			@origin = <$F>;
			chomp @origin;
			close $F;
		}
		else {
			$origin[1] = (stat('clipboard/'.$d))[9];
			$origin[2] = F::filename2nice($d);
		}
		my @l = localtime $origin[1];
		$b .= '<li><a href="add.pl?paste='.$d.'&ipos='.$_[1].'&dir='.$_[2].'" title="Paste '.$d.' from '
		.sprintf("%4s-%02s-%02s, %02s:%02s:%02s", $l[5]+1900,$l[4]+1,$l[3],$l[2],$l[1],$l[0]).'">'
		.$origin[2].'</a></li>';
	}
	closedir $D;
	return $a.'<ul><li>or paste from clipboard:</li>'.$b.'</ul></div>';
}
	
1;
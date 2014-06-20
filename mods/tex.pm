#!perl -w
package tex; #V 2013dec23 init template, goon prints to next marker 
no warnings 'uninitialized';
use strict;
#use person;
#use datum;
use F;
use File::Copy qw(copy);

my @part = ("");
my @partname = ();
my $id = 0;

sub new
{
	my $c = shift;
	my $s = {};
	$s->{'mode'} = 'tex';
	my @a = ();
	$s->{'bib'} = \@a;
	bless $s, $c;
	return $s;
}

sub init # file
{
	my $s = shift;
	my $k = 0;
	open T, shift or print "Open template fails\n";
	while (<T>) {
		if (/^(.*)\%([A-Z]+)\%(.*)$/) {
			$part[$k] .= $1;
			$partname[$k] = $2;
			$part[++$k] = $3."\n"; }
		else {
			$part[$k] .= $_; }}
	close T;
}

sub goon { my $s = shift; print shift @part; return shift @partname; }

sub navitem { my $s = shift; return '<li><a href="index.pl?chapter='.$_[0].'">'.($_[1]?$_[1]: F::filename2nice($_[0])).'</a></li>'; }

sub searchhead {
	my $s = shift;
	return '<div class="info">Searching: <code>'.shift.'</code></div>'
	.'<style>h1,h2,h3,h4,h5,h6,h7 { margin:0;padding:1px; font-size:16px; }</style>'; }

sub appendix { my $s = shift; return '' if $_[0]; }

sub heading {
	my $s = shift;
	my $h = '\paragraph';
	$h = '\chapter' if $_[2] == 1;
	$h = '\section' if $_[2] == 2;
	$h = '\subsection' if $_[2] == 3;
	$h = '\subsubsection' if $_[2] == 4;
	return $h.'{'.F::filename2nice($_[1]).'}'."\n\n"; }

sub tocitem {
	my $s = shift;
	return '<a href="#'.$_[2].'"><span class="count">'.$_[0].'</span> '.F::filename2nice($_[1]).'</a>'; }

sub LINK { my $s = shift; 
	my $x = shift;
	#$x =~ s/\\/x/g;
	$x =~ s/([^\\])\\([^\\])/$1\\\\$2/g;
	my $shorturl = $x;
	$shorturl =~ s/^\w+tps?\:\/\/([^\/]+).*$/$1\/.../;
	return '\href{'.$x.'}{'.$shorturl.'}'; }
sub RQ   { my $s = shift; return '\RQ{'.shift."}"; }
sub TODO { my $s = shift; return '\TODO{'.shift."}\n"; }
sub ASK { my $s = shift; return '\ASK{'.ucfirst(shift)."}\n"; }
sub AHA { my $s = shift; return '\AHA{'.shift."}\n"; }
sub CITE { my $s = shift; $s->{'cite'}++; return '\ding{126} '; } #\begin{quote} #.shift."\n".'\end{quote} '; }
sub REF {
	my $s = shift; 
	my $x = shift; 
	my $first = $x=~/\,/?substr($x,0,index($x,',')):$x;
	my $additional = substr($x,index($x,','));
	my $r = '\citep{'.$s->bib($first, $x).'}';
	if ($s->{'cite'}) { $r = "\n".$r."\n"; $s->{'cite'}--; } #.'\end{quote} '
	
	return $r; }
sub FILE {
	my $s = shift; 
	my ($a, $b) = split /\./, substr($_[0], rindex($_[0], '/')+1);
	return '['.$a.'.'.$b.'] '; }
sub IMG { # name caption span
	my $s = shift; 
	my ($path,$caption,$span) = @_;
	chomp $path;
	my $name = substr $path, rindex($path, '/')+1;
	my $noext = $1 if $path=~/^(.+)\.\w+$/;
	my $noextname = $1 if $name=~/^(.+)\.\w+$/;
	
	mkdir 'tex/img/' if not -d 'tex/img';
	
	if ($name=~/\.svg$/i) {
		if (not -f 'tex/img/'.$noextname.'.pdf') {
			#print STDOUT 'inkscape -z -D --file='.$path.' --export-pdf=tex/img/'.$noextname.'.pdf'."\n";
			#system 'inkscape -z -D --file='.$path.' --export-pdf=tex/img/'.$noextname.'.pdf';
			#print STDOUT "$!\n$?\n" if $!; 
			print STDOUT 'rsvg-convert.exe -f pdf -o tex/img/'.$noextname.'.pdf '.$path."\n";
			system 'rsvg-convert.exe -f pdf -o tex/img/'.$noextname.'.pdf '.$path;
			#print STDOUT "$!\n$?\n" if $!; 
			
			}
		else {
			print STDOUT 'tex/img/'.$noextname.'.pdf already exists.'."\n"; }
		$path = 'img/'.$noextname.'.pdf';
	}
	else {
        $path = '../'.$path; }
	
	return '\begin{figure'.($span?'*}':'}[H]').'
\centering
\includegraphics[width=\linewidth]{'.$path.'}
\caption{'.$caption.'}
\label{'.$name.'}
\end{figure'.($span?'*':'').'}'."\n";
}

sub FLAG {
	my $s = shift; return '\label{'.$_[0].'}'; }
sub SEE {
	my $s = shift; return '\ref{'.$_[0].'}'; }

sub bib 
{
	my $s = shift;
	if (@_)
	{ 
		my $year = int($2) if $_[0]=~/^(.+)\s*(\d{4})(\w)?/;
		my $nname = $1;
		my $multi = $3;
		my $name = F::nice2filename($nname);
		$name =~ s/_//g;
		#$name =~ s/etal\.?/ \{\\it\et\~al\}\., /;
		my @rest = split /\,\s+/, $_[1];
		shift @rest;
		s/^(\w+\:(\/|\\).+)$/\\url\{$1\}/ for @rest;
		s/^(\w+.+)$/\{\\bf $1\}/ for @rest;
	
		if (not grep /$name$year$multi/, @{$s->{'bib'}}) {
			push( @{$s->{'bib'}}, 
			'\bibitem['.$nname.', '.$year.$multi.']{'.$name.$year.$multi.'} '
			.$nname.' ('.$year.'), '.(@rest?join(', ',@rest):'')); }
		return $name.$year.$multi;
	}
	return join( "\n\n", sort {lc$a cmp lc$b} @{$s->{'bib'}});
}


sub authors # chapter
{
	my $s = shift; 
    my $c = shift;
    my $r = '';
    open my $F, 'chapter/'.$c.'/'.$c.'.txt';
	while (<$F>) {
        if (/^AUTHORS? (.+)\s*$/) { $r = $1; last; }}
	close $F;
	if (not $r and -f 'config/author.txt') {
        open my $A, 'config/author.txt'; my @configauthor = <$A>; close $A;
        $r = join(', ', grep(/^[^\#]/, @configauthor)); }
    my $lastname = $1 if $r =~ /^\S+\s+([^\,]+)/;
	return '\author['.$lastname.' \textit{et~al}]{'.$r.'}';
} 

sub content # file, search
{
	my $s = shift; 
	my $r = '';
	$s->{'cite'} = 0;
	my $path = substr $_[0], 0, rindex($_[0], '/')+1;
	open my $F, shift;
	my $search = shift;
	my ($list, $table, $align) = 0;
	while (<$F>)
	{
		$align++ if /\\begin\{align/;
		
		next if $search and not /$search/i;
		s/(([a-z]|https?):(\\|\/|\/\/)\S+)/$s->LINK($1)/gei;
		s/FILE\s+(.+)(\s*)$/$s->FILE($path.$1)/ge;
		s/TODO\s+(.+)(\s*)$/$s->TODO($1)/ge;
		s/ASK\s+(.+)(\s*)$/$s->ASK($1)/ge;
		s/CITE(\s+)/$s->CITE.$1/ge;
		s/\(REF\s+([^\)]+)\)/$s->REF($1)/ge;
		s/REF\s+(.+)(\s*)$/$s->REF($1).$2/ge;
		s/AHA\s+(.+)(\s*)$/$s->AHA($1).$2/ge;
		s/RQ\s+(.+)(\s*)$/$s->RQ($1).$2/ge;
		s/IMG\s+([^ ]+)(\s+.+)?(\s*)$/$s->IMG($path.$1,$2).$3/ge;
		s/IMG\*\s+([^ ]+)(\s+.+)?(\s*)$/$s->IMG($path.$1,$2,1).$3/ge;
		s/FLAG\s+(\w+)/$s->FLAG($1).$2/ge;
		s/SEE\s+(\w+)/$s->SEE($1)/ge;
		s/(^|\s)\*([^\*]+)\*(\s|\.|\,|$)/$1\\bb\{$2\}$3/g;
		s/\&lt\;/</g; s/\&gt\;/>/g; s/\&/\\&/g if not $align;
		s/CODE\s+(.+)(\s*)$/\\mono\{$1\}\\\\$2/g;
		s/AUTHORS\s+(.+)(\s*)$/$2/g;
		s/\#/\\#/g;
		s/\%/\\%/g;
		s/\&amp\;/&/g;
		
		$align=0 if /\\end\{align/;

		if (/^\n/ and $s->{'cite'}) {
			$_ = "\n"; #.'\end{quote} '
			$s->{'cite'}--; }
			
		if (/(^|\n)-\s+(.+)$/) {
			$_ = '\item '.$2."\n";
			$r .= '\begin{itemize}'."\n" if not $list;
			$list++; }
		elsif ($list) {
			$_ = '\end{itemize}'."\n".$_;
			$list = 0; }
		
		if (/(^|\n)\|\s+(.+)\|\s+$/) {
			$_ = $2."\\\\ \\hline\n";
			my $spalten = 1+ s/\|/\&/g;
			$r .= '\begin{center}'."\n".'\begin{tabular}{|'.('l|'x $spalten).'}'."\n\\hline\n" if not $table;
			$table++; }
		elsif ($table) {
			$_ = '\end{tabular}'."\n".'\end{center}'."\n".$_;
			$table = 0; }	
			
		$r .= $_;
	}
	if ($list) { $r .= "\n".'\end{itemize}';}
	if ($table) { $r .= "\n".'\end{tabular}'."\n".'\end{center}'; }
	close $F;
	return $r ? ''.$r."\n\n" : '';
}

sub title
{
	my $s = shift; 
	my $r = '';
	if (-f 'chapter/title.txt') {
		open my $F, 'chapter/title.txt';
		while (<$F>)
		{
			s/(https?:\/\/\S+)/$s->LINK($1)/ge;
			s/\n/\\\\/g;
			$r .= $_;
		}
		close $F; }
	elsif ($_[0]) {
		$r = F::filename2nice($_[0]); }
	return $r ? $r : '';
}

1;
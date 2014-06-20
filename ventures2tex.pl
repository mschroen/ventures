#!perl -w
$|=1;
no warnings 'uninitialized';
use lib 'mods';
use F;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use File::Copy qw(copy);
my $cgi = new CGI;
my $CHAPTER = $cgi->param('chapter');
my $RERUN = $cgi->param('rerun') ? $cgi->param('rerun') : 0;
my ($CHNUM, $CHSHOW) = 0;

use html;
my $O = html->new;
$O->init('mods/template-clean.htm');
mkdir 'tex' if not -d 'tex';
	
my $FHMAIN = undef;
# Start

	my $TOC = '';

	while (my $tmp = $O->goon)
	{
	# CHAPTER 
		if ($tmp eq 'CHAPTER') { 

			print $CHAPTER; }
		
	# ARTICLE 
		if ($tmp eq 'ARTICLE') { 
			
			print '<pre style="font-family: Consolas, monospace;margin-left: 1em;">';
			
			if ($cgi->param('clean')) {
				my ($i, $j) = 0;
				(unlink($_)?$i++ : $j++) foreach glob "img/*.pdf tex/*.aux tex/*.out tex/*.log tex/*.toc";
				print '<span style="color: blue">-- Removed '.$i.' temporary files'.($j?' ('.$j.' failed: '.$!.')':'').'</span>'."\n"; }
				
			if ($cgi->param('clean') or not $RERUN)
			{
				print '<span style="color: blue">-- Writing tex files ...</span><div style="color:#888;margin-left: 1.7em;">';
				
				open $FHMAIN, '>tex/'.$CHAPTER.'.tex';
				select $FHMAIN;
				
				require tex;
				my $T = tex->new;
				if (-f 'config/template.tex') { $T->init('config/template.tex'); }
				else { $T->init('mods/template.tex'); }
		
				while (my $tmp2 = $T->goon)
				{
					if ($tmp2 eq 'INCLUDES') { 
						&recur('chapter/'.$CHAPTER,'', $T); }
					
					elsif ($tmp2 eq 'AUTHORS') {
						print $T->authors($CHAPTER); }
						
					elsif ($tmp2 eq 'TITLE') {
						print $T->title($CHAPTER); }
						
					elsif ($tmp2 eq 'ABSTRACT') {
						print $T->content('chapter/'.$CHAPTER.'/'.$CHAPTER.'.txt'); }
					
					elsif ($tmp2 eq 'BIB') {
						print $T->bib; }
					
					elsif ($tmp2 eq 'DATE') {
						print F::today; }
					
					elsif (not $tmp2) { exit; }
				}
				
				close $FHMAIN; select STDOUT;
				print '</div><span style="color: green">   Done.</span>'."\n";
			}
			
			print '<span style="color: blue">-- pdflatex tex/'.$CHAPTER.'.tex</span>'."\n";
			print '<div style="color:#888;margin-left: 1.7em;">';
			chdir 'tex/';
			#system 'pdflatex '.$CHAPTER.'.tex';
			open (my $pipe, 'pdflatex '.$CHAPTER.'.tex |');
			while (<$pipe>) {
				s/^(.*error.*)$/\<span style="color:red;font-weight:bold">$1\<\/span\>/i;
				s/^(\!.*)$/\<span style="color:red;font-weight:bold">$1\<\/span\>/i;
				s/^(.*warning.*)$/\<span style="color:orange;font-weight:bold">$1\<\/span\>/i;
				s/^(.*Output written.*)$/\<span style="color:green;font-weight:bold">$1\<\/span\>/i;
				print;
				}
			copy($CHAPTER.'.pdf', '../chapter/'.$CHAPTER.'/'.$CHAPTER.'.pdf')
			or print '<span style="color:red;font-weight:bold">Can not copy pdf to chapter/'.$CHAPTER.'/'.$CHAPTER.'.pdf , is it in use/opened?'."\n";
			
			print '</div><span style="color: green">   Done.'."\n";
			print '-&gt; </span><a id="venturespdf" href="chapter/'.$CHAPTER.'/'.$CHAPTER.'.pdf" style="background-color: #AF0; padding: 0.2em 0.5em; color: green; text-decoration:none;">chapter/'.$CHAPTER.'/'.$CHAPTER.'.pdf</a> ('.int((-s '../chapter/'.$CHAPTER.'/'.$CHAPTER.'.pdf')/1024).' KB)'."\n";
			print "\n".'</pre>';
			print '<ul class="links sans"><li><a href="index.pl?chapter='.$CHAPTER.'">Back</a></li>';
			print '<li><a href="ventures2tex.pl?chapter='.$CHAPTER.'&rerun='.++$RERUN.'#venturespdf">rerun</a></li>';
			print '<li><a href="ventures2tex.pl?chapter='.$CHAPTER.'&clean=1&rerun='.$RERUN.'#venturespdf">clean &amp; rerun</a></li>';
			print '</ul>';
		}
	
	# 0	
		elsif (not $tmp) { exit; }
	}

sub recur # path count object
{
	my $path = shift;
	my $parent = substr $path, rindex($path, '/')+1;
	my $lvl = () = $path =~ /\//g;
	my $count = shift;
	my $X = shift;
	my $i = 0;
	my $appendix = '';
	foreach my $line (&index($path))
	{
		my ($name, $show) = split /\t+/, $line;
		my $e = $path.'/'.$name;

		if (-f $e) { 
			# show main text 
			if ($name eq $parent.'.txt' and not $parent eq $CHAPTER) {
				print $X->content($e, $SEARCH); }
			# list files 
			else { $appendix .= $X->FILE($e, $SEARCH); }}
			
		elsif (-d $e) {
			if ($path eq 'chapter') {
				close $FH if $FH;
				select $FHMAIN;
				print '\include{chapter/'.$name.'}'."\n";
				open $FH, '>tex/chapter/'.$name.'.tex';
				print STDOUT 'tex/chapter/'.$name.'.tex'."\n";
				select $FH; }
			else {
				print $X->appendix($appendix); $appendix=''; }
			# recur folders 
			$i++;
			print $X->heading("$count$i.", $show, $lvl+1, $name);
			$TOC .= $X->tocitem("$count$i.", $show, $name);

			&recur($e, "$count$i.", $X); }
			#if ($O->{'mode'} eq 'tex') { close $FH; select $FHMAIN; }}
	}
}
	
sub index # path
{
	my $path = shift;
	my $section = substr $path, rindex($path, '/')+1;
	my (@index, @files, @o, @list) = ();
	
	# read index if folder exists 
	if ( -f $path.'/index' ) {
		open my $F, $path.'/index';
		while (<$F>) {
			if ( /^([^\t]+)\t+(.+)$/ ) {
				push @index, $_ if -d $path.'/'.$1;
				push @o, $1; }}
		close $F; }
	#else { print 'no index'; }
	
	# read all entries 
	my @globed = grep {not /\/\.+$/ and not /\/index$/ and not /\/$section\.txt$/ and $_ ne 'chapter/title.txt'} glob $path.'/*';
	my @dirs = grep { -d $_ } @globed;
	
	# add untracked folders
	if ($#index != $#dirs) {
		#print 'index refreshed';
		foreach my $e (map {s/$path\///;$_} sort {lc$a cmp lc$b} @dirs ) {
			push @index, $e."\t".F::filename2nice($e)."\n" if not grep {$_ eq $e} @o; }
		# update index 
		open my $F, '>'.$path.'/index';	print $F @index; close $F; }

	# read files 
	foreach my $e (map {s/$path\///;$_} sort {lc$a cmp lc$b} @globed ) {
		push @files, $e."\n" if -f $path.'/'.$e; }
	
	# list content, files, folders 
	push @list, $section.".txt\n" if -f $path.'/'.$section.'.txt';
	push @list, @files, @index;

	return map {s/\s+$//;$_} @list;
}

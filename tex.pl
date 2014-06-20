#!perl -w
$|=1;
no warnings 'uninitialized';
use lib 'mods';
use F;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
my $cgi = new CGI;
my $CHAPTER = $cgi->param('chapter');
my ($CHNUM, $CHSHOW) = 0;

# Output mode

my ($FH, $FHMAIN) = undef;
my $O = undef;

	print "content-type:text/html\n\n".'<h1>Ventures 2 tex</h1><hr><pre style="font-family: Consolas, monospace; width: 45%; float:left;">';
	open $FHMAIN, '>tex/ventures.tex';
	select $FHMAIN;
	use tex;
	$O = tex->new;
	$O->init('mods/template.tex');
	
	print STDOUT "1. Template initiated.\n";
	
# Start

	my $TOC = '';

	while (my $tmp = $O->goon)
	{
	# CHAPTER 
		if ($tmp eq 'CHAPTER') { 

			print $CHAPTER; }

	# MSG 
		elsif ($tmp eq 'MSG') {
		
			print $O->searchhead($SEARCH) if $SEARCH; }
				
	# ARTICLE 
		elsif ($tmp eq 'INCLUDES') { 
			
			if ($CHAPTER) {
				print $O->heading($CHNUM.'.', $CHSHOW, 1, $CHAPTER);
				$TOC .= $O->tocitem($CHNUM.'.', $CHSHOW, $CHAPTER);
				&recur('chapter/'.$CHAPTER, $CHNUM.'.'); }
			else {
				&recur('chapter',''); }}
				
	# TITLE 
	
		elsif ($tmp eq 'TITLE') { 
		
			print $O->title; }
				
	# 0	
		elsif (not $tmp) { exit; }
	}

close $FHMAIN if $FHMAIN;
print STDOUT "tex files written.\npdflatex tex/ventures.tex\n";
print '<div style="color:#888;margin-left: 1em;">';
chdir 'tex/';
system "pdflatex ventures.tex";
print STDOUT '</div></pre><pre style="font-family: Consolas, monospace; width: 45%; float:left;">pdflatex done.'."\n";
print STDOUT '<a href="tex/ventures.pdf">tex/ventures.pdf</a> '.int((-s 'ventures.pdf')/1024).' KB</pre>';


sub recur
{
	my $path = shift;
	my $parent = substr $path, rindex($path, '/')+1;
	my $lvl = () = $path =~ /\//g;
	my $count = shift;
	my $i = 0;
	my $appendix = '';
	foreach my $line (&index($path))
	{
		my ($name, $show) = split /\t+/, $line;
		my $e = $path.'/'.$name;

		if (-f $e) { 
			# show main text 
			if ($name eq $parent.'.txt') { print $O->content($e, ''); }
			# list files 
			else { $appendix .= $O->FILE($e, $SEARCH); }}
			
		elsif (-d $e) {
			if ($path eq 'chapter') {
				close $FH if $FH;
				select $FHMAIN;
				print '\include{chapter/'.$name.'}'."\n";
				open $FH, '>tex/chapter/'.$name.'.tex';
				select $FH; }
			else {
				print $O->appendix($appendix); $appendix=''; }
			# recur folders 
			$i++;
			print $O->heading("$count$i.", $show, $lvl+1, $name);
			$TOC .= $O->tocitem("$count$i.", $show, $name);

			&recur($e, "$count$i."); }
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
	else { print 'no index'; }
	
	# read all entries 
	my @globed = grep {not /\/\.+$/ and not /\/index$/ and not /\/$section\.txt$/ and $_ ne 'chapter/title.txt'} glob $path.'/*';
	my @dirs = grep { -d $_ } @globed;
	
	# add untracked folders
	if ($#index != $#dirs) {
		print 'index refreshed';
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

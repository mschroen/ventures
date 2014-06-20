#!perl -w
$|=1;
no warnings 'uninitialized';
use lib 'mods';
use F;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
my $cgi = new CGI;
my $CHAPTER = $cgi->param('chapter');
my $SEARCH = $cgi->param('search');
   $SEARCH = '(^|\s)'.$cgi->param('csearch').'\s' if $cgi->param('csearch');
my ($CHNUM, $CHSHOW) = 0;

# Output mode

use html;
my $O = html->new($SEARCH);
$O->init('mods/template.htm');
	
# Start

	my $TOC = '';

	while (my $tmp = $O->goon)
	{
	# CHAPTER 
		if ($tmp eq 'CHAPTER') { 

			print $CHAPTER; }

	# NAV 
		if ($tmp eq 'NAV') { 
		
			my $i = 0;
			open my $F, 'chapter/index';
			while (<$F>) { 
				if ( /^([^\t]+)\t+(.+)$/ ) {
					print $O->navitem($1, ++$i, $2, $CHAPTER);
					if ($1 eq $CHAPTER) {
						$CHNUM = $i;
						$CHSHOW = $2; }}}
			close $F; }

	# MSG 
		elsif ($tmp eq 'MSG') {
		
			print $O->searchhead($SEARCH) if $SEARCH; }
				
	# ARTICLE 
		elsif ($tmp eq 'ARTICLE') { 
			
			if ($CHAPTER) {
				print $O->section_start('chapter', $CHAPTER, 1);
				print $O->heading($CHNUM.'.', $CHSHOW, 1, $CHAPTER);
				$TOC .= $O->tocitem_start($CHNUM.'.', $CHSHOW, $CHAPTER);
				&recur('chapter/'.$CHAPTER, $CHNUM.'.');
				$TOC .= $O->tocitem_end; }
			else {
				print $O->title if not $SEARCH;
				&recur('chapter',''); }}
				
	# TITLE 
	
		elsif ($tmp eq 'TITLE') { 
		
			print $O->title; }
				
	# TOC 
		elsif ($tmp eq 'TOC') { 
		
			print $TOC; }
			
	# IDS 
		elsif ($tmp eq 'IDS') { 
		
			print $O->IDS; }
	
	# TEXLINK
		elsif ($tmp eq 'TEXLINK') { 
		
			print '<li><a href="ventures2tex.pl?chapter='.$CHAPTER.'#venturespdf" class="feature">TeX</a></li>' if $CHAPTER; }
		

	# 0	
		elsif (not $tmp) { exit; }
	}

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
		chmod(0777, $e) if sprintf("%04o\n", (stat($e))[2] & 07777) !~/777/;
		
		if (-f $e)
		{ 
			# show main text 
			if ($name eq $parent.'.txt') { print $O->content($e, $SEARCH); }
			# list files 
			else { $appendix .= $O->FILE($e, $SEARCH); }
		}
		elsif (-d $e)
		{
			print $O->appendix($appendix); $appendix='';
			# recur folders 
			$i++;
			print $O->section_start($path, $name, 0, $i);
			print $O->heading("$count$i.", $show, $lvl+1, $name);
			$TOC .= $O->tocitem_start("$count$i.", $show, $name);

			&recur($e, "$count$i.");
		}
	}
	print $O->appendix($appendix) if $appendix;
	print $O->section_end($path, 0, $i);
	$TOC .= $O->tocitem_end;
}
	
sub index # path
{
	my $path = shift;
	my $section = substr $path, rindex($path, '/')+1;
	my (@index, @files, @o, @list) = ();
	
	# read index if folder exists 
	if ( -f $path.'/index' ) {
		open (my $F, $path.'/index') or print $s->error('Unable to read index: '.$!);
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
		#print '<div class="info">index refreshed</div>';
		foreach my $e (map {s/$path\///;$_} sort {lc$a cmp lc$b} @dirs ) {
			push @index, $e."\t".F::filename2nice($e)."\n" if not grep {$_ eq $e} @o; }
		# update index 
		open (my $F, '>'.$path.'/index') or print $s->error('Unable to write index: '.$!);
		print $F @index; close $F; }

	# read files 
	foreach my $e (map {s/$path\///;$_} sort {lc$a cmp lc$b} @globed ) {
		push @files, $e."\n" if -f $path.'/'.$e; }
	
	# create section.txt
	if (not -f $path.'/'.$section.'.txt' and $path ne 'chapter') {
		open(my $xfh, '>'.$path.'/'.$section.'.txt') or print $s->error('Unable to touch content: '.$!);
		print $xfh ''; close $xfh; }
	
	# list content, files, folders 
	push @list, $section.".txt\n";
	push @list, @files, @index;

	return map {s/\s+$//;$_} @list;
}

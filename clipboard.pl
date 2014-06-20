#!perl -w
$|=1;
no warnings 'uninitialized';
use lib 'mods';
use F;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
my $cgi = new CGI;

# Output mode

use html;
my $O = html->new();
$O->init('mods/template-clean.htm');
	
# Start

	while (my $tmp = $O->goon)
	{
		
	# ARTICLE 
		if ($tmp eq 'ARTICLE') { 
			
			print $O->title('Clipboard');
			&recur('clipboard'); }
			
	# IDS 
		elsif ($tmp eq 'IDS') { 
		
			print $O->IDS;
			#print $O->Clips;
			}
			
	# 0	
		elsif (not $tmp) { exit; }
	}

1;

sub recur
{
	my $path = shift;
	my $parent = substr $path, rindex($path, '/')+1;
	my $lvl = () = $path =~ /\//g;
	my $appendix = '';
	foreach my $line (&index($path))
	{
		my ($name, $show) = split /\t+/, $line;
		my $e = $path.'/'.$name;

		if (-f $e)
		{ 
			$appendix .= $O->FILE($e);
		}
		elsif (-d $e)
		{
			print $O->appendix($appendix); $appendix='';
			# recur folders 
			print $O->clipboard_section_start($path, $name, $lvl-1);
			print $O->clipboard_heading($show, $lvl+1, $e);

			&recur($e);
		}
	}
	print $O->section_end($path,1);
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
	
	# read all entries 
	my @globed = grep {not /\/\.+$/ and not /\/\.origin$/ and not /\/index$/ and not /\/$section\.txt$/ } glob $path.'/*';
	my @dirs = grep { -d $_ } @globed;
	
	# add untracked folders
	if ($#index != $#dirs) {
		foreach my $e (map {s/$path\///;$_} sort {lc$a cmp lc$b} @dirs ) {
			push @index, $e."\t".F::filename2nice($e)."\n" if not grep {$_ eq $e} @o; }}

	# read files 
	foreach my $e (map {s/$path\///;$_} sort {lc$a cmp lc$b} @globed ) {
		push @files, $e."\n" if -f $path.'/'.$e; }
	
	# list content, files, folders 
	push @list, $section.".txt\n";
	push @list, @files, @index;

	return map {s/\s+$//;$_} @list;
}

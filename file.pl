#!perl -w
$|=1;
no warnings 'uninitialized';
use lib 'mods';
use F;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
my $cgi = new CGI;
my $FILE = $cgi->param('file');
my $CONTENT = $cgi->param('content');
my $READ = $cgi->param('read');

# Output mode

use html;
my $O = html->new;

my $name = substr $FILE, rindex($FILE,'/')+1;
my $path = $FILE.'/';

print "content-type:text/html\n\n";

if (defined $cgi->param('content')) 
{
	$CONTENT =~ s/<div><br><\/div>/\n/gi;
	$CONTENT =~ s/<div>/\n/gi;
	$CONTENT =~ s/<br>/\n/gi;
	$CONTENT =~ s/<[^>]+>//g;
	$CONTENT =~ s/\&nbsp\;/ /g;
	open (my $F, '>'.$path.$name.'.txt') or die $!;
	print $F $CONTENT;
	close $F;

	print $O->content($path.$name.'.txt', 0, 1);
}
elsif ($READ)
{ 
	my $r = '';
	open (my $F, $path.$name.'.txt') or die $!;
	while (<$F>) { $r .= $_; }
	close $F;
	print $r ? $r : '(empty)';
}


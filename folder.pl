#!perl -w
$|=1;
no warnings 'uninitialized';
use lib 'mods';
use F;
use File::Copy;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
my $cgi = new CGI;
my $FOLDER = $cgi->param('folder');
my $NICENAME = $cgi->param('name');
my $CUT = $cgi->param('cut');
my $DELETE = $cgi->param('delete');

# Output mode

use html;
my $O = html->new;

my $name = substr $FOLDER, rindex($FOLDER,'/')+1;
my $path = substr $FOLDER, 0, rindex($FOLDER,'/')+1;

print "content-type:text/html\n\n";

if ($NICENAME) 
{
	my $raw = F::nice2filename($NICENAME);
	my @index = ();
	open (my $F, $path.'index') or die $!;
	while (<$F>) {
		$_ = $raw."\t".$NICENAME."\n" if /^$name\t/;
		push @index, $_; }
	close $F;
	open (my $G, '>'.$path.'index'); print $G @index; close $G;
	
	move($path.$name, $path.$raw);
	if (not move($path.$raw.'/'.$name.'.txt', $path.$raw.'/'.$raw.'.txt')) {
		print $O->error('Unable to move and rename content: '.$1);
		open (my $Q, $path.$raw.'/'.$name.'.txt') or die $O->error('Unable to open content: '.$!);
		my @qq = <$Q>; close $Q; open (my $P, '>clipboard/'.$name.'.txt'); print $P @qq; close $P;
		print $O->error('Wrote backup to clipboard/'.$name.'.txt'); }
	print $path.$raw;
}
elsif ($CUT) 
{
	mkdir 'clipboard' if not -d 'clipboard';

	# move folder 
	my $v = $name; my $i = 0;
	while (-d 'clipboard/'.$v) { $v = $name.'-'.++$i; }
	move($path.$name, 'clipboard/'.$v) or die "$!\n$path$name\n$v\n";
	
	# update index
	my @index = ();
	my $nn = ''; $i = 0; my $pos = 0;
	open (my $F, $path.'index') or die $!;
	while (<$F>) {
		if ( /^$name\t(.+)\s+$/ ) {	$nn = $1; $pos = $i; }
		else { push @index, $_; }
		$i++; }
	close $F;
	open (my $G, '>'.$path.'index'); print $G @index; close $G;
	
	# create origin 
	open my $FC, '>clipboard/'.$v.'/.origin';
	print $FC $path."\n".time."\n".$nn."\n".$pos."\n";
	close $FC;
	
	# info
	print html::cutted($v);
}
elsif ($DELETE) 
{
	mkdir 'trash' if not -d 'trash';

	# move folder 
	my $v = $name; my $i = 0;
	while (-d 'trash/'.$v) { $v = $name.'-'.++$i; }
	move($path.$name, 'trash/'.$v);
	
	# create origin 
	open my $FT, '>trash/'.$v.'/.origin';
	print $FT $path."\n".time;
	close $FT;
	
	# update index
	my @index = ();
	open (my $F, $path.'index') or die $!;
	while (<$F>) {
		push @index, $_ if not /^$name\t/; }
	close $F;
	open (my $G, '>'.$path.'index'); print $G @index; close $G;
	
	# info
	print html::deleted($v);
}
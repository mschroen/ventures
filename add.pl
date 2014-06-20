#!perl -w
$|=1;
no warnings 'uninitialized';
use lib 'mods';
use F;
use File::Copy;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
my $cgi = new CGI;
my $RESTORE = $cgi->param('restore');
my $MENU = $cgi->param('menu');
my $PASTE = $cgi->param('paste');
my $NEW = $cgi->param('newsectionname');
my $IPOS = $cgi->param('ipos');
my $DIR = $cgi->param('dir');

# Output mode

use html;
my $O = html->new;


if ($RESTORE) 
{
	print "content-type:text/html\n\n";
	my $name = substr $RESTORE, rindex($RESTORE,'/')+1;
	my $path = substr $RESTORE, 0, rindex($RESTORE,'/')+1;
	
	# read + remove origin 
	open (my $FO, $RESTORE.'/.origin') or die $!; # RPATH TIME NICENAME INDEXPOS
	my @origin = <$FO>;
	chomp @origin;
	close $FO;
	unlink $RESTORE.'/.origin';

	# move folder 
	my $v = $name; $v=~s/-\d+$//; my $i = 0;
	while (-d $origin[0].$v) { $v = $name.'-'.++$i; }
	move($RESTORE, $origin[0].$v);
	
	# update index
	open (my $F, $origin[0].'index') or die $!;	my @index = <$F>; close $F;
	splice(@index, ($origin[3] ne '' ?$origin[3]:$#index+1),0, $v."\t".$origin[2]."\n");
	open (my $G, '>'.$origin[0].'index'); print $G @index; close $G;
	
	# info
	my $chapter = '';
	$chapter = '?chapter='.$1 if $origin[0] =~ /^chapter\/(\w+)\//;
	$chapter = '?chapter='.$v if $origin[0] eq 'chapter/';
	print '/ventures/index.pl'.$chapter;
}
elsif ($MENU=~/\d+/) 
{
	print "content-type:text/html\n\n";
	print $O->newmenu($MENU, $IPOS, $DIR);
}
elsif ($PASTE) 
{
	my $name = F::filename2nice($PASTE);
	if (-f 'clipboard/'.$PASTE.'/.origin')
	{
		open my $F, 'clipboard/'.$PASTE.'/.origin';	my @origin = <$F>; chomp @origin; close $F;
		$name = $_[2] if $_[2];
		unlink 'clipboard/'.$PASTE.'/.origin';
	}
	move('clipboard/'.$PASTE, $DIR.$PASTE) or die $!." move $PASTE\n";
	
	my @index = ();
	if (-f $DIR.'index') {
		open (my $F, $DIR.'index') or die $!." $DIR index\n"; @index = <$F>; close $F; }
	splice( @index, ($IPOS==0?0:$IPOS-1), 0, "$PASTE\t$name\n");
	open (my $G, '>'.$DIR.'index'); print $G @index; close $G;
	
	my $chapter = $1 if $DIR =~ /^chapter\/(\w+)\//;
	my $anchor = $PASTE;
	print "Location: http://localhost/ventures/index.pl?chapter=".$chapter."#".$anchor."\n\n";

}
elsif ($NEW) 
{
	my $name = F::nice2filename($NEW);
	mkdir $DIR.$name or die $!." mkdir $DIR$name\n";
	
	my @index = ();
	if (-f $DIR.'index') {
		open (my $F, $DIR.'index') or die $!." $DIR index\n"; @index = <$F>; close $F; }
	splice( @index, ($IPOS==0?0:($IPOS<0?@index:$IPOS-1)), 0, "$name\t$NEW\n"); # push==splice(@a,@a,0,$x)
	open (my $G, '>'.$DIR.'index'); print $G @index; close $G;
	
	my $chapter = $1 if $DIR =~ /^chapter\/(\w+)\//;
	my $anchor = $name;
	print "Location: http://localhost/ventures/index.pl?chapter=".$chapter."#".$anchor."\n\n";
}
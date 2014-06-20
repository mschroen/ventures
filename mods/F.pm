#!perl -w

package F;
use strict;

sub nice2filename {
	my $_ = shift;
	s/ä/ae/gi; s/ö/oe/gi; s/ü/ue/gi; s/ß/ss/gi;
	s/\W+/_/g;
	return $_;
}
sub filename2nice {
	my $_ = shift;
	s/_+/ /g; s/\/$//;
	return $_;
}

my @UNIQ = ();
sub uniq
{
	my $uniq = undef;
	while (not $uniq or grep {$_ eq $uniq} @UNIQ) {
		$uniq = int rand 9999; }
	push @UNIQ, $uniq;
	return $uniq;
}

sub today
{
	my @l = localtime;
	my @monthname = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
	return sprintf("%s %s, %.2d", 1900+$l[5], $monthname[$l[4]], $l[3]);
}

1;
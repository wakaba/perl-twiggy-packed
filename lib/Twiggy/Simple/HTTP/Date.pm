package Twiggy::Simple::HTTP::Date;
use strict;
use warnings;

use vars qw(@DoW @MoY %MoY);
@DoW = qw(Sun Mon Tue Wed Thu Fri Sat);
@MoY = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
@MoY{@MoY} = (1..12);

sub time2str (;$)
{
    my $time = shift;
    $time = time unless defined $time;
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($time);
    sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT",
                $DoW[$wday],
                $mday, $MoY[$mon], $year+1900,
                $hour, $min, $sec);
}

1;

=head1 COPYRIGHT

Copyright 1995-1999, Gisle Aas

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package PerlIO::via::dynamic;
use strict;
our $VERSION = '0.01';

=head1 NAME

PerlIO::via::dynamic - dynamic PerlIO layers

=head1 SYNOPSIS

 open $fh, $fname;
 $p = PerlIO::via::dynamic->new
  (translate =>
    sub { $_[1] =~ s/\$Filename[:\w\s\-\.\/\\]*\$/\$Filename: $fname\$/e},
   untranslate =>
    sub { $_[1] =~ s/\$Filename[:\w\s\-\.\/\\]*\$/\$Filename\$/});
 binmode $fh, $p->via;

=head1 DESCRIPTION

PerlIO::via::dynamic is used for creating dynamic PerlIO layers. It is
useful when the behavior or the layer depends on variables.

You need to use the constructor to create new layers, with two
arguments: translate and untranslate. Then use C<$p-E<gt>via> as
layers in binmode or open.

=cut

sub PUSHED {
    die "this should not be via directly"
	if $_[0] eq __PACKAGE__;
    bless \*PUSHED, $_[0];
}

sub translate {
}

sub untranslate {
}

sub FILL {
    my $line = readline( $_[1] );
    $_[0]->untranslate ($line) if defined $line;
    $line;
}

sub WRITE {
    my $buf = $_[1];
    $_[0]->translate($buf);
    (print {$_[2]} $buf) ? length($buf) : -1;
}

sub SEEK {
    seek ($_[3], $_[1], $_[2]);
}

sub new {
    my ($class, %arg) = @_;
    my $self = {};
    my $package = 'PerlIO::via::dynamic'.substr("$self", 7, -1);
    eval qq|
package $package;
our \@ISA = qw($class);

1;
| or die $@;

    no strict 'refs';
    for (keys %arg) {
	*{"$package\::$_"} = $arg{$_};
    }
    bless $self, $package;
    return $self;
}

sub via {
    ':via('.ref ($_[0]).')';
}

=head1 TODO

The namespaces created by PerlIO::via::dynamic::new is never
destroyed. a parameter should be used to determine if the lifetime of
the namespace is the same as the PerlIO::via::dynamic
object. Otherwise it should be associated with the handles that use
it.

=head1 AUTHORS

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 by Chia-liang Kao E<lt>clkao@clkao.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

1;

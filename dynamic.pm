package PerlIO::via::dynamic;
use strict;
our $VERSION = '0.02';

=head1 NAME

PerlIO::via::dynamic - dynamic PerlIO layers

=head1 SYNOPSIS

 open $fh, $fname;
 $p = PerlIO::via::dynamic->new
  (translate =>
    sub { $_[1] =~ s/\$Filename[:\w\s\-\.\/\\]*\$/\$Filename: $fname\$/e},
   untranslate =>
    sub { $_[1] =~ s/\$Filename[:\w\s\-\.\/\\]*\$/\$Filename\$/});
 $p->via ($fh);
 binmode $fh, $p->via; # deprecated

=head1 DESCRIPTION

PerlIO::via::dynamic is used for creating dynamic PerlIO layers. It is
useful when the behavior or the layer depends on variables. You should
not use this module as via layer directly (ie :via(dynamic)).

Use the constructor to create new layers, with two arguments:
translate and untranslate. Then use C<$p-E<gt>via ($fh)> to wrap the
handle.

Note that PerlIO::via::dynamic uses the scalar fields to reference to
the object representing the dynamic namespace. If you

=cut

use Symbol qw(delete_package gensym);
use Scalar::Util qw(weaken);

sub PUSHED {
    die "this should not be via directly"
	if $_[0] eq __PACKAGE__;
    my $p = bless gensym(), $_[0];

    no strict 'refs';
    # make sure the blessed glob is destroyed
    # earlier than the object representing the namespace.
    ${*$p} = ${"$_[0]::EGO"};

    return $p;
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
    ${"$package\::EGO"} = $self;
    weaken ${"$package\::EGO"};
    return $self;
}

sub via {
    my ($self, $fh) = @_;
    my $via = ':via('.ref ($_[0]).')';
    unless ($fh) {
	# 0.01 compatibility
	$self->{nogc} = 1;
	return $via;
    }
    binmode ($fh, $via) or die $!;
    if (defined ${*$fh}) {
	warn "handle $fh cannot hold references, namespace won't be cleaned";
    }
    else {
	${*$fh} = $self;
    }
}

sub DESTROY {
    my ($self) = @_;
    return unless UNIVERSAL::isa ($self, 'HASH');
    return if $self->{nogc};

    no strict 'refs';
    my $ref = ref($self);
    my ($leaf) = ($ref =~ /([^:]+)$/);
    $leaf .= '::';

    for my $sym (keys %{$ref.'::'}) {
	undef ${$ref.'::'}{$sym}
	    if $sym;
    }

    delete $PerlIO::via::{$leaf};
}

=head1 AUTHORS

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 by Chia-liang Kao E<lt>clkao@clkao.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

1;

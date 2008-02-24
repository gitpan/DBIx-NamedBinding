package DBIx::NamedBinding;

use warnings;
use strict;

use DBI;
our $VERSION = '0.01';
our @ISA     = 'DBI';

package DBIx::NamedBinding::db;
BEGIN { our @ISA = ('DBI::db') }

my %position_of;

sub prepare {
    my ($dbh, $statement, @args) = @_;
    my @parameters = $statement =~ m/ : (\w+) \b /gx;   # get param names
    my $position = 1;
    my $param_pos = { map { $_ => $position++ } @parameters };
    $statement =~ s/ : \w+ \b /?/gx;                    # replace names w/ ?'s
    my $sth = $dbh->SUPER::prepare($statement, @args)
        or return;
    $sth->{private_namedbinding_pos} = $param_pos;
    return $sth;
}

package DBIx::NamedBinding::st;
BEGIN { our @ISA = ('DBI::st') }

sub bind_param {
    my ($sth, $param, $value) = @_;
    Carp::croak('missing parameter') if !defined $param || !$param;
    return $sth->set_err(1234, "Missing named binding parameter", undef, "bind_param")
        if !defined $param || !$param;
    return $sth->set_err(1234, "Invalid named binding parameter", undef, "bind_param")
        if $param =~ /\W/;
    my $param_pos = $sth->{private_namedbinding_pos};
    if ($param !~ /^\d+\Z/) {
        return $sth->set_err(1234, "Named binding identifier '$param' was not used in preparing this statement handle",
            undef, "bind_param")
            if ! exists $param_pos->{$param};
        $param = $param_pos->{$param};
    }
    $sth->SUPER::bind_param($param, $value);
}

1;

__END__

=head1 NAME

DBIx::NamedBinding - use named parameters instead of '?'

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

This module subclasses the DBI and allows you to use named query parameter
placeholders instead of positional '?'.

    use DBI;

    my $dbh = DBI->connect($dsn, {
        RootClass => 'DBIx::NamedBinding',
    } );
    my $sth = $dbh->prepare('
        SELECT * FROM foo WHERE
            price        <     :price     AND
            sale_price   =     0          AND
            location     =     :location  AND
            inventory    >     :inventory AND
            sku          LIKE  :sku
    ');
    $sth->bind_param( price     => 14.95  );
    $sth->bind_param( location  => 'BMWH' );
    $sth->bind_param( inventory => 4      );
    $sth->bind_param( sku       => 'OH%'  );

    my $rv = $sth->execute();
        
Other than that, just use it like one would use the DBI.

=head1 AUTHOR

Andrew Sweger, C<< <yDNA at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbi-namedbinding at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBI-NamedBinding>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::NamedBinding


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBI-NamedBinding>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBI-NamedBinding>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBI-NamedBinding>

=item * Search CPAN

L<http://search.cpan.org/dist/DBI-NamedBinding>

=back


=head1 ACKNOWLEDGEMENTS

My thanks to Colin Meyer for turning me on to the evils of subclassing the
DBI.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Andrew Sweger, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


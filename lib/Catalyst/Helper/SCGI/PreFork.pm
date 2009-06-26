package Catalyst::Helper::SCGI::PreFork;

use warnings;
use strict;
use Config;
use File::Spec;

our $VERSION = '0.01';

=head1 NAME

Catalyst::Helper::SCGI::PreFork - A helper to create a Catalyst SCGI engine script.

=head1 SYNOPSIS

Use the helper to build the SCGI::PreFork runner.

    $ script/myapp_create.pl SCGI::PreFork
	
=head1 DESCRIPTION

This helper module creates the runner script for the SCGI engine.

=head2 $self->mk_stuff ( $c, $helper, @args )
 
    Create SCGI runner script

=cut

sub mk_stuff {
    my ( $self, $helper, @args ) = @_;

    my $base = $helper->{base};
    my $app  = lc($helper->{app});

    $helper->render_file( "scgi_script",
        File::Spec->catfile( $base, 'script', "$app\_scgi.pl" ) );
    chmod 0700, "$base/script/$app\_scgi.pl";
}

=head1 AUTHOR

Orlando Vazquez, C< <orlandov at cpan.org> >

=head1 BUGS

Please report any bugs or feature requests to
C<orlandov at cpan.org>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2009 Orlando Vazquez, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

__DATA__

__scgi_script__
#!/usr/bin/env perl

BEGIN { $ENV{CATALYST_ENGINE} ||= 'SCGI::PreFork' }

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../lib";
use [% app %];

my $help = 0;
my ( $port, $detach );
 
GetOptions(
    'help|?'    => \$help,
    'port|p=s'  => \$port,
    'daemon|d'  => \$detach,
);

pod2usage(1) if $help;

[% app %]->run( 
    $port, 
    $detach,
);

1;

=head1 NAME

[% app %]_scgi.pl - The pre-forking Catalyst SCGI engine

=head1 SYNOPSIS

[% app %]_scgi.pl [options]
 
 Options:
   -? -help     display this help and exits
   -p -port    	Port to listen on
   -d -daemon   daemonize

=head1 DESCRIPTION

Run a Catalyst application as SCGI.

=head1 AUTHOR

Orlando Vazquez C<< orlandov@cpan.org >>

=head1 COPYRIGHT

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

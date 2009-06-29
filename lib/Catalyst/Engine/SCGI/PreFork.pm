package Catalyst::Engine::SCGI::PreFork;
use Moose;
use SCGI;
use SCGI::Request;
use Catalyst::Engine::SCGI::PreFork::Handler;

use constant DEBUG => 0;

BEGIN { extends 'Net::Server::PreFork' }

our $VERSION = '0.01';

sub run {
    my ($self, $class, $port, $host, $options) = @_;

    $self->{appclass} = $class;
    $self->{options} = $options;
       
    $self->{appclass}->engine(
        Catalyst::Engine::SCGI::PreFork::Handler->new($self->{server})
    );

    @ARGV = @{ $options->{argv} };

    my %extra;
    if ( $options->{pidfile} or $options->{pid_file} ) {
        $extra{pid_file} = $options->{pidfile} || $options->{pid_file};
    } 

    if ( $options->{background} ) {
        $extra{setsid} = $extra{background} = 1;
    }

    $self->SUPER::run(
        port                       => $port || 3000,
        host                       => $host || '*',
        serialize                  => 'flock',
        log_level                  => DEBUG || $ENV{'CATALYST_DEBUG'} ? 4 : 1,
        min_servers                => $options->{min_servers}       || 5,
        min_spare_servers          => $options->{min_spare_servers} || 2,
        max_spare_servers          => $options->{max_spare_servers} || 10,
        max_servers                => $options->{max_servers}       || 50,
        max_requests               => $options->{max_requests}      || 1000,
        leave_children_open_on_hup => $options->{restart_graceful}  || 0,

        %extra
    );
}

sub process_request {
    my ($self) = @_;

    # create scgi request object from Net::Server client socket
    my $scgi = SCGI::Request->_new($self->{server}{client}, 1);

    eval { $scgi->read_env };
    if ($@) {
        # error
        warn "ZOMG errorz $@";
    }
    else {
        $self->{appclass}->engine->{scgi} = $scgi;
        $self->{appclass}->handle_request(env => $scgi->env);
        $scgi->close;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;

__END__

=head1 NAME

Catalyst::Engine::SCGI::PreFork - Pre-forking Catalyst engine

=head1 SYNOPSIS

    CATALYST_ENGINE=SCGI::PreFork \
        script/myapp_server.pl [options] -- [SCGI::PreFork options]

=head1 DESCRIPTION

This engine is designed to be used in conjunction with an HTTP server that
supports the SCGI 1 protocol.

=head1 OPTIONS

You may specify these options as command line parameters to your server
launcher. Additional options may be passed to the engine by modifying
yourapp_server.pl to send additional items to the run() method.

=head2 --min_server

The minimum number of servers to keep running. Default is 5.

=head2 --min_spare_servers

The minimum number of servers to have waiting for requests. Minimum and
maximum numbers should not be set too close to each other or the server will
fork and kill children too often.  Defaults to 2.

=head2 --max_spare_servers

The maximum number of servers to have waiting for requests.  Defaults to 10.

=head2 --max_servers

The maximum number of child servers to start.  Defaults to 50.

=head2 --max_requests

Restart a child after it has served this many requests.  Defaults to 1000.
Note that setting this value to 0 will not cause the child to serve unlimited
requests.  This is a limitation of Net::Server and may be fixed in a future
version.

=head2 --restart_graceful

This enables Net::Server's leave_children_open_on_hup option.  If set, the parent
will not attempt to close child processes if the parent receives a SIGHUP.  Each
child will exit as soon as possible after processing the current request if any.

=head2 --pidfile

This passes through to Net::Server's pid_file option.  If set, the pidfile is
written to the path.  Default is none.  This file is not removed on server exit 

=head2 --background

This option passes through to Net::Server and also sets the 'setsid' option to
true.

=head1 ACKNOWLEDGEMENTS

This engine is based heavily on Catalyst::Engine::HTTP::PreFork and
Catalyst::Engine::SCGI.

=head1 AUTHOR

Orlando Vazquez <orlandov at cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

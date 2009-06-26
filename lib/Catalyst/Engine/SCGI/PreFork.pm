package Catalyst::Engine::SCGI::PreFork;
use Moose;
use SCGI;
use SCGI::Request;
use Catalyst::Engine::SCGI::PreFork::Handler;

use constant DEBUG => 1;

BEGIN { extends 'Net::Server::PreFork' }

our $VERSION = '0.03';

sub run {
    my ( $self, $class, $port, $detach ) = @_;

    my $options = {};
    $self->{appclass} = $class;
    $self->{options} = $options;
       
    # TODO dont hardwire these
    $port = 9999 unless defined $port;
    my $host = '*';


    my $engine
        = Catalyst::Engine::SCGI::PreFork::Handler->new($self->{server});
    $self->{appclass}->engine($engine);

    my %extra = ();
    if ( $options->{pidfile} or $options->{pid_file} ) {
        $extra{pid_file} = $options->{pidfile} || $options->{pid_file};
    } 

    if ( $options->{background} ) {
        $extra{setsid} = $extra{background} = 1;
    }

=for

    my $socket = IO::Socket::INET->new(
        Listen    => 5,
        ReuseAddr => 1,
        LocalPort => $port,
    ) or die "cannot bind to port $port: $!";
    $sock = SCGI->new( $socket, blocking => 1 )
      or die "Failed to open SCGI socket; $!";

    $self->daemon_fork()   if defined $detach;
    $self->daemon_detach() if defined $detach;
    while ( my $request = $sock->accept ) {
        eval { $request->read_env };
        if ($@) {

            # some error
        }
        else {
            $self->{_request} = $request;
            $class->handle_request( env => $request->env );
            # make sure to close once we are done.
            $request->close();
        }
    }
=cut

    $self->SUPER::run(
        port                       => $port || 3000,
        host                       => $host || '*',
        serialize                  => 'flock',
        log_level                  => DEBUG ? 4 : 1,
        min_servers                => $options->{min_servers}       || 5,
        min_spare_servers          => $options->{min_spare_servers} || 2,
        max_spare_servers          => $options->{max_spare_servers} || 10,
        max_servers                => $options->{max_servers}       || 50,
        max_requests               => $options->{max_requests}      || 1000,
        leave_children_open_on_hup => $options->{restart_graceful}  || 0,

        %extra
    );
}

sub post_accept_hook {
    my $self = shift;
    $self->{client} = {};
}

sub process_request {
    my ($self) = @_;
    my $scgi = SCGI::Request->_new($self->{server}{client}, 1);

    eval { $scgi->read_env };
    if ($@) {
        # error
        warn "ZOMG errorsz $@";
    }
    else {
        $self->{appclass}->engine->{scgi} = $scgi;
        $self->{appclass}->handle_request(env => $scgi->env);
        $scgi->close;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

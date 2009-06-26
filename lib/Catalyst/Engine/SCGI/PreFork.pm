package Catalyst::Engine::SCGI::PreFork;
use Moose;
use SCGI;
use SCGI::Request;
use Catalyst::Engine::SCGI::PreFork::Handler;

use constant DEBUG => 0;

BEGIN { extends 'Net::Server::PreFork' }

our $VERSION = '0.01';

sub run {
    my ( $self, $class, $port, $detach ) = @_;

    my $options = {};
    $self->{appclass} = $class;
    $self->{options} = $options;
       
    # TODO dont hardcode these
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

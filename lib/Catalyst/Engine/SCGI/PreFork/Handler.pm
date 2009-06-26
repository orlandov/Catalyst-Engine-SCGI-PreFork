package Catalyst::Engine::SCGI::PreFork::Handler;
use Moose;

BEGIN { extends 'Catalyst::Engine::CGI' }

our $VERSION = '0.01';

sub finalize_headers {
    my ( $self, $c ) = @_;
    $c->response->header( Status => $c->response->status );
    $self->{scgi}->connection->print(
        $c->response->headers->as_string("\015\012") . "\015\012" );
}

sub write {
    my ( $self, $c, $buffer ) = @_;
 
    unless ( $self->{_prepared_write} ) {
        $self->prepare_write($c);
        $self->{_prepared_write} = 1;
    }
 
    $self->{scgi}->connection->print($buffer);
}

sub read_chunk {
    my ( $self, $c ) = @_;
    my $rc = read( $self->{scgi}->connection, $_[2], $_[3] );
    return $rc;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

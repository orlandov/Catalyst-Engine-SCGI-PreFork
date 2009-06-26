#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Engine::SCGI::PreFork' );
}

diag( "Testing Catalyst::Engine::SCGI::PreFork $Catalyst::Engine::SCGI::PreFork::VERSION, Perl $], $^X" );

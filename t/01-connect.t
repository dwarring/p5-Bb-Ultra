use warnings; use strict;
use Test::More tests => 16;
use Test::Fatal;

use lib '.';
use t::Ultra;
use Date::Parse;
use Scalar::Util qw<looks_like_number>;

SKIP: {
    my %t = t::Ultra->test_connection;
    my $connection = $t{connection};
    skip $t{skip} || 'skipping live tests', 16
	unless $connection;

    ok $connection->issuer, 'issuer';
    ok $connection->secret, 'secret';
    ok $connection->host, 'host';

    is exception { $connection->connect; }, undef, "connection lives";

    my $auth_start = $connection->auth_start;
    ok $auth_start, 'auth_start';

    my $t = time();
    ok $auth_start > $t - 60 && $auth_start <= $t + 60, 'auth_start'
	or diag "time:$t auth_start:$auth_start";

    my $auth = $connection->auth;

    isa_ok $auth, 'Bb::Collaborate::Ultra::Connection::Auth', 'auth';
    ok $auth->access_token, 'access_token';
    my $expires = $auth->expires_in;
    ok $expires, 'expires_in';
    ok $expires > 0 && $expires <= 1000, 'expires_in'
	or diag "expires: $expires";

    use Bb::Collaborate::Ultra::Session;
    my $start = $t + 300;
    my $end = $start + 1800;

    my $msg = $connection->post(
	'Bb::Collaborate::Ultra::Session' => {
	    name => 'Test Session',
	    startTime => $start,
	    endTime   => $end,
	});
    my $session = Bb::Collaborate::Ultra::Session->construct($msg, connection => $connection);
    my $session_id = $session->id;
    ok $session_id, 'got session_id';
    ok $session->created, "session creation";
    ok looks_like_number $session->created, "created data-type"
	or diag "created: " .  $session->created;

    $session = undef;

    $session = $connection->get('Bb::Collaborate::Ultra::Session' => {
	id => $session_id,
    });

    ok $session->created, "session creation";
    ok looks_like_number $session->created, "created data-type"
	or diag "created: " .  $session->created;

    is exception {
	$connection->del('Bb::Collaborate::Ultra::Session' => {
	    id => $session->id,
	});
    }, undef, "session deletion lives";
}

done_testing;

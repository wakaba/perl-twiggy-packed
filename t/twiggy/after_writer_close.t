use strict;
use warnings;

use Test::Requires qw(AnyEvent::HTTP);
use AnyEvent;
use AnyEvent::Util;
use AnyEvent::HTTP;
use Test::More;
use Test::TCP;
use Plack::Loader;

sub do_request {
    my ( $url ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $cond = AnyEvent->condvar;

    http_get $url, timeout => 3, sub {
        my ( $data, $headers ) = @_;

        is $headers->{'Status'}, 200, 'status code';
        is $data, 'a', 'response body';
        $cond->send;
    };
    $cond->recv;
}

my ($pipe_r, $pipe_w) = portable_pipe;
my $app = sub {
    my ( $env ) = @_;

    return sub {
        my ( $respond ) = @_;

        AE::postpone {
            my $writer = $respond->( [200, ['Content-Type', 'text/plain'] ] );
            $writer->write('a');
            $writer->close;
            print $pipe_w "1\n";
            my $timer; $timer = AE::timer 1, 0, sub {
                undef $writer;
                print $pipe_w "2\n";
                close $pipe_w;
                undef $timer;
            };
        };
    };
};

my $server = Test::TCP->new(
    code => sub {
        my ( $port ) = @_;

        my $server = Plack::Loader->load('Twiggy', port => $port, host => '127.0.0.1');
        $server->run($app);
        exit;
    },
);
close $pipe_w;

do_request('http://127.0.0.1:' . $server->port);

kill 'QUIT' => $server->pid;
my $hanged = 0;
local $SIG{ALRM} = sub { $hanged = 1; kill 'TERM' => $server->pid; };
alarm(5);
waitpid($server->pid, 0);
alarm(0);
is $hanged, 0, "server should shut down";

my $result = do {
  local $/ = undef;
  <$pipe_r>;
};
is $result, qq{1\n2\n}, "destroy finished";

done_testing();

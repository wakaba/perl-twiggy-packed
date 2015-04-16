use Test::More;
use Plack::MIME;

is( Plack::MIME->mime_type(".vcd"), undef );

Plack::MIME->set_fallback(sub { 'application/x-cdlink' });
is( Plack::MIME->mime_type(".vcd"), "application/x-cdlink" );

done_testing;

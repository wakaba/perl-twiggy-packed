package Plack::Builder;
use strict;
use parent qw( Exporter );
our @EXPORT = qw( builder add enable );

use Carp ();
use Scalar::Util ();
use Plack::Util ();

sub new {
    my $class = shift;
    bless { middlewares => [ ] }, $class;
}

sub add_middleware {
    my($self, $mw, @args) = @_;

    if (ref $mw ne 'CODE') {
        my $mw_class = Plack::Util::load_class($mw, 'Plack::Middleware');
        $mw = sub { $mw_class->wrap($_[0], @args) };
    }

    push @{$self->{middlewares}}, $mw;
}

# do you want remove_middleware() etc.?

sub to_app {
    my($self, $app) = @_;

    if ($app) {
        $self->wrap($app);
    } else {
        Carp::croak("to_app() is called without application to build.");
    }
}

sub wrap {
    my($self, $app) = @_;

    for my $mw (reverse @{$self->{middlewares}}) {
        $app = $mw->($app);
    }

    $app;
}

# DSL goes here
our $_add = our $_add_if = sub {
    Carp::croak("enable should be called inside builder {} block");
};

sub enable         { $_add->(@_) }

sub builder(&) {
    my $block = shift;

    my $self = __PACKAGE__->new;

    local $_add = sub {
        $self->add_middleware(@_);
    };
    local $_add_if = sub {
        $self->add_middleware_if(@_);
    };

    my $app = $block->();

    $app = $app->to_app if $app and Scalar::Util::blessed($app) and $app->can('to_app');

    $self->to_app($app);
}

1;

__END__

=head1 NAME

Plack::Builder - OO and DSL to enable Plack Middlewares

=head1 SYNOPSIS

  # in .psgi
  use Plack::Builder;

  my $app = sub { ... };

  builder {
      enable "Deflater";
      enable "Session", store => "File";
      enable "Debug", panels => [ qw(DBITrace Memory Timer) ];
      enable "+My::Plack::Middleware";
      $app;
  };

  # using OO interface
  my $builder = Plack::Builder->new;
  $builder->add_middleware('Foo', opt => 1);
  $builder->add_middleware('Bar');
  $builder->wrap($app);

=head1 DESCRIPTION

Plack::Builder gives you a quick domain specific language (DSL) to
wrap your application with L<Plack::Middleware> subclasses. The
middleware you're trying to use should use L<Plack::Middleware> as a
base class to use this DSL, inspired by Rack::Builder.

Whenever you call C<enable> on any middleware, the middleware app is
pushed to the stack inside the builder, and then reversed when it
actually creates a wrapped application handler. C<"Plack::Middleware::">
is added as a prefix by default. So:

  builder {
      enable "Foo";
      enable "Bar", opt => "val";
      $app;
  };

is syntactically equal to:

  $app = Plack::Middleware::Bar->wrap($app, opt => "val");
  $app = Plack::Middleware::Foo->wrap($app);

In other words, you're supposed to C<enable> middleware from outer to inner.

=head1 INLINE MIDDLEWARE

Plack::Builder allows you to code middleware inline using a nested
code reference.

If the first argument to C<enable> is a code reference, it will be
passed an C<$app> and should return another code reference
which is a PSGI application that consumes C<$env> at runtime. So:

  builder {
      enable sub {
          my $app = shift;
          sub {
              my $env = shift;
              # do preprocessing
              my $res = $app->($env);
              # do postprocessing
              return $res;
          };
      };
      $app;
  };

is equal to:

  my $mw = sub {
      my $app = shift;
      sub { my $env = shift; $app->($env) };
  };

  $app = $mw->($app);

=head1 OBJECT ORIENTED INTERFACE

Object oriented interface supports the same functionality with the DSL
version in a clearer interface, probably with more typing required.

  my $builder_out = Plack::Builder->new;
  my $builder_in  = Plack::Builder->new;
  $builder_in->add_middleware('Foo');
  $builder_out->to_app;

=head1 SEE ALSO

L<Plack::Middleware> L<Plack::App::URLMap> L<Plack::Middleware::Conditional>

=cut




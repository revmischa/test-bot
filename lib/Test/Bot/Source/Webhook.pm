package Test::Bot::Source::Webhook;

use Moose::Role;

# requires 'parse_payload';

use AnyEvent;
use Twiggy::Server;
use Plack::Request;

has '_http_server' => (
    is  => 'rw',
    isa => 'Twiggy::Server',
);

has 'port' => (
    is => 'rw',
    isa => 'Int',
    default => 4000,
);

# run a simple HTTP server listening for github post-commit pings
sub watch {
    my ($self) = @_;
    
    my $server = Twiggy::Server->new(
        port => $self->port,
    );

    my $app = sub {
        my $env = shift;
        my $req = Plack::Request->new($env);
        my $res = $req->new_response(200);

        $res->content_type('text/html; charset=utf-8');

        if ($req->path eq '/') {
            # index page
            $res->content("Yup, server sure is running!");
        } elsif ($req->path eq '/post_receive') {
            my $payload = $req->param('payload');
            if ($payload) {
                my @commits = $self->parse_payload($payload);
                $self->test_and_notify(@commits);
            } else {
                $res->status(400);
                $res->content("invalid request");
            }
        } else {
            # unknown path
            $res->content("Unknown path " . $req->path);
            warn "test-github bot 404, path: " . $req->path . "\n";
            $res->code(404);
        }

        $res->finalize;
    };
    
    $server->register_service($app);
    $self->_http_server($server);

    print "Listening for post_receive hook on port " . $self->port . "\n";
}

1;

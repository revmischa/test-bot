package Test::Bot::Notify::IRC;

use Any::Moose;
with 'Test::Bot::Notify';

use AnyEvent;
use AnyEvent::IRC::Client;

has 'irc_host' => (
    is => 'rw',
    isa => 'Str',
);

has 'irc_port' => (
    is => 'rw',
    isa => 'Int',
    default => 6667,
);

has 'irc_channel' => (
    is => 'rw',
    isa => 'Str',
    default => '#db',
    required => 1,
);

has 'irc_nick' => (
    is => 'rw',
    isa => 'Str',
    default => 'test_bot',
);

has '_irc_client' => (
    is => 'rw',
    isa => 'AnyEvent::IRC::Client',
    clearer => 'clear_irc_client',
);

after 'setup' => sub {
    my ($self) = @_;

    die "irc_host is required" unless $self->irc_host;
    die "irc_channel is required" unless $self->irc_channel;
};

after notify => sub {
    my ($self, @commits) = @_;

    my $client = AnyEvent::IRC::Client->new;

    $client->reg_cb(
        connect => sub {
            my ($con, $err) = @_;
            if (defined $err) {
                warn "IRC connect error: $err\n";
                return;
            }
        },

        disconnect => sub {
            $self->clear_irc_client;
            undef $client;
        },
        
        registered => sub {
            my ($con) = @_;
            
            # connected and ready to go
            
            foreach my $commit (@commits) {
                my $msg = $self->format_commit($commit) or next;
                foreach my $line (split("\n", $msg)) {
                    $con->send_srv(PRIVMSG => $self->irc_channel, $line);
                }
            }
        },
    );

    $self->_irc_client($client);
    $client->connect($self->irc_host, $self->irc_port, { nick => $self->irc_nick });
};

sub format_commit {
    my ($self, $commit) = @_;

    my $status = $commit->test_success ? "\033[32mSUCCESS\033[0m" : "\033[31mFAILURE\033[0m";
    my $id = substr($commit->id, 0, 6);
    my $author = $commit->author || 'unknown';
    my $msg = $commit->message;

    my $output = $commit->test_output;

    my $ret = "$id ($msg) status: $status";
    $ret .= "\n$output" if $output;

    return $ret;
}

1;

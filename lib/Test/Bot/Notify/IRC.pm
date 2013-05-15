package Test::Bot::Notify::IRC;

use Moose;
with 'Test::Bot::Notify';

use AnyEvent;
use AnyEvent::IRC::Client;
use Carp qw/croak/;

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

has '_connected' => ( is => 'rw', isa => 'Bool' );

after 'setup' => sub {
    my ($self) = @_;

    die "irc_host is required" unless $self->irc_host;
    die "irc_channel is required" unless $self->irc_channel;

    $self->connect_irc;
};

sub deliver_msg {
    my ($self, @messages) = @_;

    my $msg = join("\n", @messages);
    my @lines = $self->_irc_client->send_long_message('utf-8', 0, PRIVMSG => $self->irc_channel, $msg);
}

after 'notify' => sub {
    my ($self, @messages) = @_;

    if ($self->_connected) {
        # already connected
        $self->deliver_msg(@messages);
    } else {
        $self->connect_irc(sub { $self->deliver_msg(@messages) });
    }
};

sub connect_irc {
    my ($self, $cb) = @_;

    my $client = $self->_irc_client && $self->_connected ?
        $self->_irc_client : AnyEvent::IRC::Client->new(send_initial_whois => 1);

    # connect...
    $client->reg_cb(
        connect => sub {
            my ($con, $err) = @_;
            if (defined $err) {
                warn "IRC connect error: $err\n";
                return;
            }
            $self->_connected(1);
        },

        publicmsg => sub {
            my ($con, $chan, $msg_parsed) = @_;

            my $msgref = $msg_parsed->{params};
            my $msg = $msgref->[-1];

            my $meth = $self->bot->meta->find_method_by_name('irc_publicmsg');
            if ($meth) {
                $meth->execute($self, $con, $chan, $msg);
            }
        },

        error => sub {
            my ($con, $code, $message, $ircmsg) = @_;
            warn "IRC error $code $message: $ircmsg\n";
            $con->disconnect;
        },
            
        disconnect => sub {
            warn "disconnected";
            $self->_connected(0);
            $self->clear_irc_client;
            #undef $client;
        },
        
        registered => sub {
            my ($con) = @_;

            $con->send_msg(JOIN => $self->irc_channel);

            # connected and ready to go
            $client->reg_cb(buffer_empty => sub {
                                # it would be cool to disconnect after sending out messages
                                # but this event always fires waaay too early
                                #$client->disconnect;
                            });
            $cb->() if $cb;
        },
    );

    $self->_irc_client($client);
    $client->connect($self->irc_host, $self->irc_port, { nick => $self->irc_nick });
};

sub _irc_fmt {
    my ($txt, $color) = @_;
    return "\033[${color}m" . $txt . "\033[0m";
}

sub _irc_bold {
    my ($txt) = @_;
    return "\033[1m" . $txt . "\033[2m";
}

sub format_changeset_push {
    my ($self, $cs) = @_;

    my @commits = @{ $cs->commits };
    my $commit_count = scalar(@commits);
    my $name = $cs->author_name ? _irc_fmt($cs->author_name, 35) : 'Unknown user';
    my $count = _irc_fmt($commit_count, 36);

    my $repo_name = _irc_bold(
        _irc_fmt($cs->repo_name, 35) || 'unknown repo'
    );

    my $push_msg = "$name pushed " . _irc_fmt($commit_count, 36)
        . " commit" . ($commit_count == 1 ? '' : 's')
        . " to $repo_name";

    # url
    #$push_msg .= ' (' . $cs->repo_url . ')' if $cs->repo_url;

    # display some commits
    my $commit_max = 6;
    my @commit_slice = @commits[0 .. ($commit_max - 1)];
    foreach my $commit (@commit_slice) {
        last unless $commit;

        $push_msg .= "\n - " . $self->format_commit($commit);
    }
    if (@commits > $commit_max) {
        $push_msg .= "\n - ... and " . (@commits - $commit_max) . " more commits";
    }

    return $push_msg;
}

sub format_commit_test_result {
    my ($self, $commit) = @_;

    # pass/fail
    my $status = $commit->test_success
        ? _fmt_irc('PASS', 32) : _fmt_irc('FAIL', 31);
    $status = _irc_bold($status);

    my $msg = $self->format_commit($commit);

    my $output = $commit->test_output;

    my $ret = "$msg status: $status";
    $ret .= "\n$output" if $output;

    return $ret;
}

sub format_commit {
    my ($self, $commit) = @_;

    croak "no commit passed" unless $commit;

    my $id = substr($commit->id, 0, 6);
    my $author = _irc_fmt($commit->author, 35) || 'unknown';
    my $msg = _irc_fmt($commit->message, 33);
    my $url = $commit->url;

    my $ret = "$author: $id - $msg";

    # tags
    my $tags = join(', ', @{ $commit->tags });
    $ret .= ' [' . _irc_fmt($tags, 32) . ']'
        if @{ $commit->tags };

    $ret .= " ($url)" if $url;

    warn $ret . "\n";

    return $ret;
}

1;

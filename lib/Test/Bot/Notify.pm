package Test::Bot::Notify;

use Moose::Role;

has 'bot' => (
    is => 'rw',
    isa => 'Test::Bot',
    required => 1,
);

sub notify_commits {
    my ($self, @commits) = @_;

    my @messages;
    foreach my $commit (@commits) {
        my $msg = $self->format_commit($commit) or next;
        push @messages, $msg;
    }

    $self->notify(@messages);
};

sub notify {
    my ($self, @messages) = @_;

}

sub setup {}

1;


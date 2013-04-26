package Test::Bot::Notify;

use Moose::Role;

requires 'format_changeset_push';
requires 'format_commit';
requires 'format_commit_test_result';

has 'bot' => (
    is => 'rw',
    isa => 'Test::Bot',
    required => 1,
);

sub notify_changeset_push {
    my ($self, $changeset) = @_;

    my $msg = $self->format_changeset_push($changeset);
    $self->notify($msg);
}

sub notify_changeset_test_results {
    my ($self, $changeset) = @_;

    my @messages;
    foreach my $commit (@{ $changeset->commits }) {
        my $msg = $self->format_commit_test_result($commit) or next;
        push @messages, $msg;
    }

    $self->notify(@messages);
};

sub notify {
    my ($self, @messages) = @_;

}

sub setup {}

1;


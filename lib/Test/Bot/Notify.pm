package Test::Bot::Notify;

use Moose::Role;

has 'bot' => (
    is => 'rw',
    isa => 'Test::Bot',
    required => 1,
);

sub notify {
    my ($self, @commits) = @_;

}

sub setup {}

1;


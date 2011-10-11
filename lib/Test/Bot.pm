package Test::Bot;

use Any::Moose 'Role';
use AnyEvent;
use Class::MOP;

#use Any::Moose 'X::Getopt'; # why the heck does this not work?
with 'MouseX::Getopt';

# local source repo checkout
has 'source_dir' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    traits => [ 'Getopt' ],
    cmd_flag => 'source-dir',
    cmd_aliases => 's',
);

has 'notification_modules' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    required => 0,
    traits => [ 'Getopt' ],
    cmd_flag => 'notifs',
    cmd_aliases => 'n',
    default => sub { ['Print'] },
);

has 'test_harness_module' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    traits => [ 'Getopt' ],
    cmd_flag => 'test_harness',
    cmd_aliases => 't',
    default => 'Aggregate',
);

requires 'install';
requires 'watch';

sub load_test_harness {
    my ($self) = @_;

    my $harness = $self->test_harness_module;
    my $harness_class = "Test::Bot::TestHarness::$harness";
    Class::MOP::load_class($harness_class);
    $harness_class->meta->apply($self);

    requires 'run_tests_for_commit';
}

sub load_notify_modules {
    my ($self) = @_;

    foreach my $module (@{ $self->notification_modules }) {
        my $notif_class = "Test::Bot::Notify::$module";
        Class::MOP::load_class($notif_class);
        $notif_class->meta->apply($self);
    }

    requires 'notify';
}

sub setup {}

sub run {
    my ($self) = @_;

    # load requested modules
    $self->load_test_harness;
    $self->load_notify_modules;

    $self->setup;

    # listen...
    $self->install;

    # ...and wait
    $self->watch;

    # run forever.
    AE::cv->recv;
}

1;

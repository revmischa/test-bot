package Test::Bot::TestHarness;

use Any::Moose 'Role';

requires 'run_tests_for_commit';

# run unit tests for each commit, notify on failure
sub test_and_notify {
    my ($self, @commits) = @_;

    my @to_notify;
    foreach my $commit (@commits) {
        $self->run_tests_for_commit($commit);

        next if $commit->test_success;

        # tests failed, notify
        push @to_notify, $commit;
    }

    $self->notify(@to_notify);
}

1;

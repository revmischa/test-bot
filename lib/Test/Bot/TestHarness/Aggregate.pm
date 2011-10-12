package Test::Bot::TestHarness::Aggregate;

use Any::Moose 'Role';
with 'Test::Bot::TestHarness';

use TAP::Harness;

sub run_tests_for_commit {
    my ($self, $commit) = @_;

    my $success = 0;
    my $output = 'No aggregate test output';

    print "Testing commit " . $commit->id . ' by ' . $commit->author . "...\n\n";

    my $tests_dir = $self->tests_dir
        or die "tests_dir must be configured for aggregate test harness";

    # our harness
    my $harness = TAP::Harness->new({
        verbosity => -1,
    });

    # run tests
    my $results = $harness->runtests(@{ $self->test_files });

    # get failed tests
    use Data::Dumper;
    warn Dumper($results);
    my @failed_desc  = $results->failed;
    my @exit_desc  = $results->exit;
    $success = $results->all_passed;

    unless ($success) {
        # list of failed tests
        $output  = join("\n", map { " - Failed: $_" } @failed_desc);
        $output .= join("\n", map { " - Exited unexpectedly: $_" } @exit_desc);
    }
    
    $commit->test_success($success);
    $commit->test_output($output);
}

sub cleanup {
    my ($self) = @_;

}

1;

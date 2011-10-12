package Test::Bot::TestHarness::Aggregate;

use Any::Moose 'Role';
with 'Test::Bot::TestHarness';

use TAP::Harness;

sub run_tests_for_commit {
    my ($self, $commit) = @_;

    my $success = 0;
    my $output = '';

    print "Testing commit " . $commit->id . ' by ' . $commit->author . "...\n\n";

    my $tests_dir = $self->tests_dir
        or die "tests_dir must be configured for aggregate test harness";

    # our harness
    my $harness = TAP::Harness->new({
        verbosity => -1,
        errors => 1,
    });

    # run tests
    my $results = $harness->runtests(@{ $self->test_files });

    # get failed tests
    my @failed_desc  = $results->failed;
    my @exit_desc  = $results->exit;
    $success = $results->all_passed;

    unless ($success) {
        # list of unique failed tests
        my %failed;
        %failed = map { ($_ => 1) } (@failed_desc, @exit_desc);
        
        $output  = join("\n", map { " - Failed: $_" } keys %failed);
        $output .= "\n" if $output;
    }
    
    $commit->test_success($success);
    $commit->test_output($output);
}

sub cleanup {
    my ($self) = @_;

}

1;

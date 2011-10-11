package Test::Bot::TestHarness::Aggregate;

use Any::Moose 'Role';

sub run_tests_for_commit {
    my ($self, $commit) = @_;

    my $success = 0;
    my $output = 'No aggregate test output';
    
    $commit->test_success($success);
    $commit->test_output($output);
}

1;

package Test::Bot::TestHarness::Aggregate;

use Any::Moose 'Role';
with 'Test::Bot::TestHarness';

use TAP::Harness;

has 'tests_dir' => (
    is => 'rw',
    isa => 'Str',
);

has 'test_files' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    lazy_build => 1,
);

sub _build_test_files {
    my ($self) = @_;

    my $dir = $self->tests_dir;
    return [ "$dir/uri_generation.t" ];
}

sub run_tests_for_commit {
    my ($self, $commit) = @_;

    my $success = 0;
    my $output = 'No aggregate test output';

    print "Testing commit " . $commit->id . ' by ' . $commit->author . "...\n\n";

    my $tests_dir = $self->tests_dir
        or die "tests_dir must be configured for aggregate test harness";

    my $tests_run = 0;

    my $harness = TAP::Harness->new({
        verbosity => -1,
    });
    my $results = $harness->runtests(@{ $self->test_files });

    my @failed_desc  = $results->failed;
    my $success = $results->all_passed;

    unless ($success) {
        # list of failed tests
        $output = join("\n", map { " - Failed: $_" } @failed_desc);
    }
    
    $commit->test_success($success);
    $commit->test_output($output);
}

sub cleanup {
    my ($self) = @_;

}

1;

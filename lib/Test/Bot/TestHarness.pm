package Test::Bot::TestHarness;

use Any::Moose 'Role';
use File::Find;

requires 'run_tests_for_commit';

has 'test_files' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    lazy_build => 1,
);

# dig up all .t files in tests_dir
sub _build_test_files {
    my ($self) = @_;

    # get path to tests
    my $repo_dir = $self->source_dir;
    my $dir = $self->tests_dir;

    # assume $dir is under $repo_dir unless it's an absolute path
    $dir = "$repo_dir/$dir" unless $dir =~ /^\//;

    # find .t files
    my @found;
    find(sub { /\.t$/ && push @found, $File::Find::name; }, $dir);
    
    return \@found;
}

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

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
        # check out commit, make sure that is what we are testing
        unless ($self->checkout($commit)) {
            warn "Failed to check out commit " . $commit->id . "\n";
            next;
        }

        # run the tests
        $self->run_tests_for_commit($commit);

        next if $commit->test_success;

        # tests failed, notify
        push @to_notify, $commit;
    }

    # send notifications of failed tests
    $self->notify(@to_notify);
}

# checkout $commit into $source_dir
sub checkout {
    my ($self, $commit) = @_;

    my $source_dir = $self->source_dir;
    die "Source directory $source_dir does not exist" unless -e $source_dir;
    die "You do not have write access to $source_dir" unless -w $source_dir;

    # this will have to change, obviously
    my $id = $commit->id;
    `cd $source_dir; git checkout $id`;

    return 1;
}

1;

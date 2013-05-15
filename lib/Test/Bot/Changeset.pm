# This class represents a set of commits

package Test::Bot::Changeset;

use Moose;
use DateTime;

has 'author_name' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'author_email' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'repo_description' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'repo_url' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'repo_name' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

# list of commits in this set
has 'commits' => (
    is => 'rw',
    isa => 'ArrayRef[Test::Bot::Commit]',
);


__PACKAGE__->meta->make_immutable;

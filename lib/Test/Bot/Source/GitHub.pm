package Test::Bot::Source::GitHub;

use Moose::Role;
with 'Test::Bot::Source';
with 'Test::Bot::Source::Webhook';

use JSON;
use DateTime::Format::ISO8601;
use Test::Bot::Commit;
use Carp qw/croak/;

# got a set of commits
sub parse_payload {
    my ($self, $payload) = @_;

    my $parsed = decode_json($payload) or return;

    my @commits;
    foreach my $commit_info (@{ $parsed->{commits} || []}) {
        # fields for our Test::Bot::Commit object
        my %c;

        # stringify author name
        my $author = $commit_info->{author} || {};
        my $name = $author->{name};
        my $email = $author->{email};
        if ($name) {
            $name .= " <$email>" if $email;
            $c{author} = $name;
        }

        # parse commit date
        my $timestamp = $commit_info->{timestamp};
        if ($timestamp) {
            my $dt = DateTime::Format::ISO8601->parse_datetime($timestamp);
            $c{timestamp} = $dt if $dt;
        }

        $c{message} = $commit_info->{message} if $commit_info->{message};

        # find list of modified files
        my @files = ( map { @{ $commit_info->{$_} || [] } } qw/added removed modified/ );
        $c{files} = \@files;

        $c{id} = $commit_info->{id};

        my $commit = Test::Bot::Commit->new(%c);
        push @commits, $commit;
    }

    return @commits;
}

sub install {
    my ($self) = @_;

    # add to repo post-receive hooks

}

1;

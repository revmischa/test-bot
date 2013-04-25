package Test::Bot::Source::Kiln;

use Moose::Role;
with 'Test::Bot::Source::Webhook';
with 'Test::Bot::Source';

use JSON;
use DateTime::Format::Flexible;
use Test::Bot::Commit;
use Carp qw/croak/;

# got a set of commits
sub parse_payload {
    my ($self, $payload) = @_;

    my $parsed = decode_json($payload) or return;

    my $commit_info_ref = $parsed->{commits} || [];
    my $commit_count = @$commit_info_ref;
    my @commits;
    foreach my $commit_info (@$commit_info_ref) {
        # fields for our Test::Bot::Commit object
        my %c;

        $c{author} = $commit_info->{author};

        # parse commit date
        my $timestamp = $commit_info->{timestamp};
        if ($timestamp) {
            my $dt = DateTime::Format::Flexible->parse_datetime($timestamp);
            $dt->set_time_zone('America/Los_Angeles');
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

# not implemented ... YET
sub install {}

1;

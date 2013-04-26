package Test::Bot::Source::Kiln;

use Moose::Role;
with 'Test::Bot::Source::Webhook';
with 'Test::Bot::Source';

use WWW::Shorten 'Shorl';
use WWW::Shorten 'TinyURL';

use JSON;
use DateTime::Format::Flexible;
use Test::Bot::Commit;
use Test::Bot::Changeset;
use Carp qw/croak/;

# got a set of commits
sub parse_payload {
    my ($self, $payload) = @_;

    my $parsed = decode_json($payload) or return;

    #use Data::Dump qw/ddx/;
    #ddx($parsed);

    # who pushed these commits?
    my $pusher = $parsed->{pusher};
    my $pusher_name = $pusher->{fullName};
    my $pusher_email = $pusher->{email};
    my $repo_name = $parsed->{repository}{name};
    my $repo_url = $parsed->{repository}{url};
    my $repo_desc = $parsed->{repository}{description};

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
        $c{url} = makeashorterlink($commit_info->{url});
        $c{tags} = $commit_info->{tags} || [];

        my $commit = Test::Bot::Commit->new(%c);
        push @commits, $commit;
    }

    my $cs = Test::Bot::Changeset->new(
        author_name => $pusher_name,
        author_email => $pusher_email,
        repo_name => $repo_name,
        repo_description => $repo_desc,
        repo_url => $repo_url,
        commits => \@commits,
    );

    return $cs;
}

# not implemented ... YET
sub install {}

1;

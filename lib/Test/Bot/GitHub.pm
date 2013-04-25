package Test::Bot::GitHub;

use Moose;
with 'Test::Bot::Source::Webhook';
with 'Test::Bot::Source::GitHub';

__PACKAGE__->meta->make_immutable;


package Test::Bot::Kiln;

use Moose;
with 'Test::Bot::Source::Webhook';
with 'Test::Bot::Source::Kiln';
with 'Test::Bot';

__PACKAGE__->meta->make_immutable;


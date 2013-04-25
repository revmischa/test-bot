#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;
use Test::Bot::Source::Kiln;

run_tests();

done_testing();

sub run_tests {
    my $bot = testbot::Kiln->new;

    # test webhook parsing
    my $webhook_output = q|{
        "pusher":{"fullName":"Mistor Wiggles","email":"greaseball@food.com","accesstoken":false},
         "repository":{"url":"https://hie.kilnhg.com/Code/Repositories/Group/ok/History/80808080","name":"ok","description":"","central":true,"id":128503},
         "commits":[{
            "id":"80f91608deee8c6b1a7319600361a09c55b9d99b",
            "revision":18163,
            "url":"https://hie.kilnhg.com/Code/Repositories/Group/ok/History/80808080",
            "message":"bliggity bloggity",
            "timestamp":"4/25/2013 5:35:40 AM","author":"Foo McBar <fbar@gmail.com>",
            "branch":"default",
            "tags":["tip"]
        }]
    }|;

    my @commits = $bot->parse_payload($webhook_output);
    is(scalar(@commits), 1, "Parsed commits");
    is($commits[0]->message, 'bliggity bloggity', 'Parsed message');
}

BEGIN {
    package testbot::Kiln;

    use Moose;
    with 'Test::Bot::Source::Webhook';
    with 'Test::Bot::Source::Kiln';
}
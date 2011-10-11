#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use Test::Bot::GitHub;

my $bot = Test::Bot::GitHub->new_with_options;
$bot->configure_test_harness(
    tests_dir => "$ENV{HOME}/db/mw/t",
);
$bot->configure_notifications(
    irc_host => 'irc.int80.biz',
    irc_channel => '#db',
);
$bot->run;

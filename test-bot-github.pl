#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::Bot::GitHub;

my $bot = Test::Bot::GitHub->new_with_options(
    irc_host => 'irc.int80.biz',
    irc_channel => '#db',
);
$bot->run;

package Test::Bot::Source;

use Moose::Role;

# start watching source repo for changes
requires 'watch';

# install cron, register post-commit hook, github post-receive hook, etc
requires 'install';

1;

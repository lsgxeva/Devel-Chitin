#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';

use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;

run_test(
    6,
    sub { $DB::single=1;
        foo(); 12;
        sub foo {
            $DB::single=1;
            15;
            Bar::bar();
        }
        sub Bar::bar {
            $DB::single=1;
            20;
            Bar::baz();
        }
        package Bar;
        sub baz {
            $DB::single=1;
            26;
        }
        my $subref = sub {
            $DB::single=1;
            30;
        };
        $subref->();
    },
    loc(filename => __FILE__, package => 'main', line => 12, subref => 1),
    'continue',
    loc(filename => __FILE__, package => 'main', subroutine => 'main::foo', line => 15, subref => 0),
    'continue',
    loc(filename => __FILE__, package => 'main', subroutine => 'Bar::bar', line => 20, subref => 0),
    'continue',
    loc(filename => __FILE__, package => 'Bar', subroutine => 'Bar::baz', line => 26, subref => 0),
    'continue',
    loc(filename => __FILE__, package => 'Bar', subroutine => 'ANON', line => 30, subref => 1),
    \&check_current_location,
    'done',
);

sub check_current_location {
    my($db, $loc) = @_;

    my $current_location = $db->current_location;
    my $ok = 1;
    foreach my $k ( qw( filename package subroutine line )) {
        $ok = 0 if ($loc->$k ne $current_location->$k);
    }
    Test::More::ok($ok, 'current_location()');
}


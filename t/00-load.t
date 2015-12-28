#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Code::Browser' ) || print "Bail out!\n";
}

diag( "Testing Code::Browser $Code::Browser::VERSION, Perl $], $^X" );

## no critic (Moose::RequireCleanNamespace)
use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Plugin::NoWarnings;
use Test2::Require::Module 'Moose::Util::TypeConstraints';

use Params::ValidationCompiler qw( validation_for );
use Moose::Util::TypeConstraints;

my $moose_int = find_type_constraint('Int');
subtest(
    'type can be inlined',
    sub {
        _test_int_type($moose_int);
    }
);

my $myint = subtype 'MyInt' => as 'Num' => where {/\A-?[0-9]+\z/};
subtest(
    'type cannot be inlined',
    sub {
        _test_int_type($myint);
    }
);

subtest(
    'type can be inlined but coercion cannot',
    sub {
        my $type = subtype 'ArrayRefInt', as 'ArrayRef[Int]';
        coerce $type => from 'Int' => via { [$_] };

        _test_int_to_arrayref_coercion($type);
    }
);

subtest(
    'neither type not coercion can be inlined',
    sub {
        my $type = subtype as 'ArrayRef[MyInt]';
        coerce $type => from 'Int' => via { [$_] };

        _test_int_to_arrayref_coercion($type);
    }
);

done_testing();

sub _test_int_type {
    my $type = shift;

    my $sub = validation_for(
        params => {
            foo => { type => $type },
        },
    );

    is(
        dies { $sub->( foo => 42 ) },
        undef,
        'lives when foo is an integer'
    );

    my $name = $type->name;
    like(
        dies { $sub->( foo => [] ) },
        qr/\Qfoo failed with: Validation failed for '$name' with value \E(?:ARRAY|\[ +\])/,
        'dies when foo is an arrayref'
    );
}

sub _test_int_to_arrayref_coercion {
    my $type = shift;

    my $sub = validation_for(
        params => {
            foo => { type => $type },
        },
    );

    is(
        dies { $sub->( foo => 42 ) },
        undef,
        'lives when foo is an integer'
    );

    is(
        dies { $sub->( foo => [ 42, 1 ] ) },
        undef,
        'lives when foo is an arrayref of integers'
    );

    my $name = $type->name;
    like(
        dies { $sub->( foo => {} ) },
        qr/\QValidation failed for '$name' with value \E(?:HASH|\{ +\})/,
        'dies when foo is a hashref'
    );
}

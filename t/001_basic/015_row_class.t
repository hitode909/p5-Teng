use t::Utils;
use Mock::Basic;
use Test::More;

{
    package Mock::BasicRow;
    use base qw(DBIx::Skin);

    sub setup_test_db {
        shift->do(q{
            CREATE TABLE mock_basic_row (
                id   INT,
                name TEXT
            )
        });
    }

    package Mock::BasicRow::Schema;
    use utf8;
    use DBIx::Skin::Schema::Declare;

    table {
        name 'mock_basic_row';
        pk 'id';
        columns qw/
            id
            name
        /;
    };

    table {
        name 'mock_basic_row_foo';
        pk 'id';
        columns qw/
            id
            name
        /;
        row_class 'Mock::BasicRow::FooRow';
    };

    package Mock::BasicRow::FooRow;
    use strict;
    use warnings;
    use base 'DBIx::Skin::Row';

    package Mock::BasicRow::Row::MockBasicRow;
    use strict;
    use warnings;
    use base 'DBIx::Skin::Row';

    sub foo {
        'foo'
    }
}

{
    package Mock::ExRow;
    use base qw(DBIx::Skin);

    sub setup_test_db {
        shift->do(q{
            CREATE TABLE mock_ex_row (
                id   INT,
                name TEXT
            )
        });
    }

    package Mock::ExRow::Schema;
    use utf8;
    use DBIx::Skin::Schema::Declare;

    table {
        name 'mock_ex_row';
        pk 'id';
        columns qw/
            id
            name
        /;
    };

    package Mock::ExRow::Row;
    use strict;
    use warnings;
    use base 'DBIx::Skin::Row';

    sub foo {'foo'}
}

my $dbh = t::Utils->setup_dbh;
my $db_basic = Mock::Basic->new({dbh => $dbh});
   $db_basic->setup_test_db;
   $db_basic->insert('mock_basic',{
        id   => 1,
        name => 'perl',
   });

my $db_basic_row = Mock::BasicRow->new({
    connect_info => ['dbi:SQLite:'],
});
$db_basic_row->setup_test_db;
$db_basic_row->insert('mock_basic_row',{
    id   => 1,
    name => 'perl',
});

my $db_ex_row = Mock::ExRow->new({
    connect_info => ['dbi:SQLite:'],
});
$db_ex_row->setup_test_db;
$db_ex_row->insert('mock_ex_row',{
    id   => 1,
    name => 'perl',
});

subtest 'no your row class' => sub {
    my $row = $db_basic->single('mock_basic',{id => 1});
    isa_ok $row, 'DBIx::Skin::Row';
};

subtest 'your row class' => sub {
    my $row = $db_basic_row->single('mock_basic_row',{id => 1});
    isa_ok $row, 'Mock::BasicRow::Row::MockBasicRow';
    is $row->foo, 'foo';
    is $row->id, 1;
    is $row->name, 'perl';
};

subtest 'ex row class' => sub {
    TODO: {
        todo_skip 'hmm... Does this behaviour required?', 2;

        my $row = $db_ex_row->single('mock_ex_row',{id => 1});
        isa_ok $row, 'Mock::ExRow::Row';
        is $row->foo, 'foo';
    };
};

subtest 'row_class specific Schema.pm' => sub {
    is +$db_basic_row->schema->get_row_class($db_basic_row, 'mock_basic_row_foo'), 'Mock::BasicRow::FooRow';
};

subtest 'handle' => sub {
    my $row = $db_basic->single('mock_basic',{id => 1});
    isa_ok $row->handle, 'Mock::Basic';
    can_ok $row->handle, 'single';
};

done_testing;

use strict;
use warnings;
use Test::More tests => 91;
BEGIN {
    require 't/lib/Test/Behaviour/Spec.pm';
    Test::Behaviour::Spec->import;
}
use CGI::Hatchet;

{
    describe 'CGI::Hatchet';

    it 'is a class.';

        can_ok 'CGI::Hatchet', 'new';
        is ref CGI::Hatchet->new, 'CGI::Hatchet', spec;
}

{
    describe 'keyword_name';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'keyword_name';

    it 'has a default non-empty string keyword name.';

        my $x = $q->keyword_name;
        ok defined $x && ! ref $x && $x, spec;

    it 'changes name.';

        is $q->keyword_name('other name'), 'other name', spec;

    it 'keeps last name.';

        is $q->keyword_name, 'other name', spec;
    
    it 'has the constructor-injected name.';

        my $q1 = CGI::Hatchet->new(keyword_name => 'injected');
        is $q1->keyword_name, 'injected', spec;
}

{
    describe 'max_post';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'max_post';

    it 'has a default number value.';

        my $x = $q->max_post;
        ok defined $x && ! ref $x && $x =~ /\A[0-9]+\z/msx, spec;

    it 'changes value.';

        is $q->max_post(2 * $x), 2 * $x, spec;

    it 'keeps last value.';

        is $q->max_post, 2 * $x, spec;

    it 'has the constructor-injected value.';
    
        my $q1 = CGI::Hatchet->new(max_post => 4 * $x);
        is $q1->max_post, 4 * $x, spec;
}

{
    describe 'enable_upload';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'enable_upload';

    it 'has a default boolean value.';

        my $x = $q->enable_upload;
        ok defined $x && ! ref $x, spec;

    it 'changes value.';

        is $q->enable_upload(! $x), ! $x, spec;

    it 'keeps last value.';

        is $q->enable_upload, ! $x, spec;

    it 'has the constructor-injected value.';
    
        my $q1 = CGI::Hatchet->new(enable_upload => 1);
        ok $q1->enable_upload, spec;
}

{
    describe 'block_size';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'block_size';

    it 'has a default number value.';

        my $x = $q->block_size;
        ok defined $x && ! ref $x && $x =~ /\A[0-9]+\z/msx, spec;

    it 'changes value.';

        is $q->block_size(2 * $x), 2 * $x, spec;

    it 'keeps last value.';

        is $q->block_size, 2 * $x, spec;

    it 'has the constructor-injected value.';
    
        my $q1 = CGI::Hatchet->new(block_size => 4 * $x);
        is $q1->block_size, 4 * $x, spec;
}

{
    describe 'crlf';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'crlf';

    it 'has a default non-empty string value.';

        my $x = $q->crlf;
        ok defined $x && ! ref $x && $x, spec;

    it 'changes value.';

        is $q->crlf('other name'), 'other name', spec;

    it 'keeps last value.';

        is $q->crlf, 'other name', spec;
    
    it 'has the constructor-injected value.';
    
        my $q1 = CGI::Hatchet->new(crlf => 'injected');
        is $q1->crlf, 'injected', spec;
}

{
    describe 'max_header';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'max_header';

    it 'has a default number value.';

        my $x = $q->max_header;
        ok defined $x && ! ref $x && $x =~ /\A[0-9]+\z/msx, spec;

    it 'changes value.';

        is $q->max_header(2 * $x), 2 * $x, spec;

    it 'keeps last value.';

        is $q->max_header, 2 * $x, spec;

    it 'has the constructor-injected value.';
    
        my $q1 = CGI::Hatchet->new(max_header => 4 * $x);
        is $q1->max_header, 4 * $x, spec;
}

{
    describe 'read_body';

    it 'can be done with CGI::Hatchet instance.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'read_body';
}

{
    describe 'env';

        my $env = {
            REQUEST_METHOD => 'FOO',
            QUERY_STRING => 'foo=oof&bar=rab&baz=zab',
            CONTENT_TYPE => 'application/x-test',
            CONTENT_LENGTH => 1235,
            HTTP_COOKIE => 'h=hydrogen; he=helium',
        };
        my $expected = {
            request_method => $env->{REQUEST_METHOD},
            query_string => $env->{QUERY_STRING},
            content_type => $env->{CONTENT_TYPE},
            content_length => $env->{CONTENT_LENGTH},
            raw_cookie => $env->{HTTP_COOKIE},
        };

    it 'is set with constructor-injection.';

        my $q = CGI::Hatchet->new(env => $env);
        is_deeply [@{$q}{keys %{$expected}}], [values %{$expected}], spec;

    it 'is also set with prepare_env.';

        my $q1 = CGI::Hatchet->new;
        can_ok $q1, 'prepare_env';

        $q1->prepare_env($env);
        is_deeply [@{$q1}{keys %{$expected}}], [values %{$expected}], spec;

    it 'is scanned with scan_formdata.';

        can_ok $q, 'scan_formdata';

    it 'is scanned with scan_cookie.';

        can_ok $q, 'scan_cookie';

    it 'sets request_method.';

        is $q->request_method, $env->{REQUEST_METHOD}, spec;

    it 'may be changed with request_method.';

        $q->request_method('BAR');
        is $q->request_method, 'BAR', spec;

    it 'sets query_string.';

        is $q->query_string, $env->{QUERY_STRING}, spec;

    it 'may be changed with query_string.';

        $q->query_string('hoge=fuga');
        is $q->query_string, 'hoge=fuga', spec;

    it 'sets content_type.';

        is $q->content_type, $env->{CONTENT_TYPE}, spec;

    it 'may be changed with content_type.';

        $q->content_type('application/x-test-more');
        is $q->content_type, 'application/x-test-more', spec;

    it 'sets content_length.';

        is $q->content_length, $env->{CONTENT_LENGTH}, spec;

    it 'may be changed with content_length.';

        $q->content_length(2 * $env->{CONTENT_LENGTH});
        is $q->content_length, 2 * $env->{CONTENT_LENGTH}, spec;

    it 'sets raw_cookie.';

        is $q->raw_cookie, $env->{HTTP_COOKIE}, spec;

    it 'may be changed with raw_cookie.';

        $q->raw_cookie('li=litium');
        is $q->raw_cookie, 'li=litium', spec;    
}

{
    describe 'param';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'param';

    it 'returns empty list at init.';

        is_deeply [$q->param], [], spec;

    it 'sets a value to the given key.';

        is_deeply [$q->param('foo', 'foo0')], ['foo0'], spec;

    it 'keeps a value of the key.';

        is_deeply [$q->param('foo')], ['foo0'], spec;

    it 'adds values into existence key.';

        is_deeply [$q->param('foo', 'foo1', 'foo2')],
                  ['foo0', 'foo1', 'foo2'], spec;

    it 'keeps values all of the key.';

        is_deeply [$q->param('foo')], ['foo0', 'foo1', 'foo2'], spec;

    it 'returns first value in scalar context.';

        is_deeply [scalar $q->param('foo')], ['foo0'], spec;

    it 'replaces values with arrayref.';
    
        $q->param('foo', 'foo0', 'foo1', 'foo2');
        $q->param('foo', ['Foo0', 'Foo1']);
        is_deeply [$q->param('foo')], ['Foo0', 'Foo1'], spec;

    it 'clears values in key with undef.';

        is_deeply [$q->param('foo', undef)], ['Foo0', 'Foo1'], spec;

    it 'keeps no value after undef set.';

        is_deeply [$q->param('foo')], [], spec;
}

{
    describe 'query_param';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'query_param';

    it 'returns empty list at init.';

        is_deeply [$q->query_param], [], spec;

    it 'sets a value to the given key.';

        is_deeply [$q->query_param('foo', 'foo0')], ['foo0'], spec;

    it 'keeps a value of the key.';

        is_deeply [$q->query_param('foo')], ['foo0'], spec;

    it 'adds values into existence key.';

        is_deeply [$q->query_param('foo', 'foo1', 'foo2')],
                  ['foo0', 'foo1', 'foo2'], spec;

    it 'keeps values all of the key.';

        is_deeply [$q->query_param('foo')], ['foo0', 'foo1', 'foo2'], spec;

    it 'returns first value in scalar context.';

        is_deeply [scalar $q->query_param('foo')], ['foo0'], spec;

    it 'replaces values with arrayref.';
    
        $q->query_param('foo', 'foo0', 'foo1', 'foo2');
        $q->query_param('foo', ['Foo0', 'Foo1']);
        is_deeply [$q->query_param('foo')], ['Foo0', 'Foo1'], spec;

    it 'clears values in key with undef.';

        is_deeply [$q->query_param('foo', undef)], ['Foo0', 'Foo1'], spec;

    it 'keeps no value after undef set.';

        is_deeply [$q->query_param('foo')], [], spec;
}

{
    describe 'upload_info';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'upload_info';

    it 'returns empty list at init.';

        is_deeply [$q->upload_info], [], spec;

    it 'sets a value to the given key.';

        is_deeply [$q->upload_info('foo', 'foo0')], ['foo0'], spec;

    it 'keeps a value of the key.';

        is_deeply [$q->upload_info('foo')], ['foo0'], spec;

    it 'adds values into existence key.';

        is_deeply [$q->upload_info('foo', 'foo1', 'foo2')],
                  ['foo0', 'foo1', 'foo2'], spec;

    it 'keeps values all of the key.';

        is_deeply [$q->upload_info('foo')], ['foo0', 'foo1', 'foo2'], spec;

    it 'returns first value in scalar context.';

        is_deeply [scalar $q->upload_info('foo')], ['foo0'], spec;

    it 'replaces values with arrayref.';
    
        $q->upload_info('foo', 'foo0', 'foo1', 'foo2');
        $q->upload_info('foo', ['Foo0', 'Foo1']);
        is_deeply [$q->upload_info('foo')], ['Foo0', 'Foo1'], spec;

    it 'clears values in key with undef.';

        is_deeply [$q->upload_info('foo', undef)], ['Foo0', 'Foo1'], spec;

    it 'keeps no value after undef set.';

        is_deeply [$q->upload_info('foo')], [], spec;
}

{
    describe 'cookie';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'cookie';

    it 'returns empty list at init.';

        is_deeply [$q->cookie], [], spec;

    it 'sets a value to the given key.';

        is_deeply [$q->cookie('foo', 'foo0')], ['foo0'], spec;

    it 'keeps a value of the key.';

        is_deeply [$q->cookie('foo')], ['foo0'], spec;

    it 'adds values into existence key.';

        is_deeply [$q->cookie('foo', 'foo1', 'foo2')],
                  ['foo0', 'foo1', 'foo2'], spec;

    it 'keeps values all of the key.';

        is_deeply [$q->cookie('foo')], ['foo0', 'foo1', 'foo2'], spec;

    it 'returns first value in scalar context.';

        is_deeply [scalar $q->cookie('foo')], ['foo0'], spec;

    it 'replaces values with arrayref.';
    
        $q->cookie('foo', 'foo0', 'foo1', 'foo2');
        $q->cookie('foo', ['Foo0', 'Foo1']);
        is_deeply [$q->cookie('foo')], ['Foo0', 'Foo1'], spec;

    it 'clears values in key with undef.';

        is_deeply [$q->cookie('foo', undef)], ['Foo0', 'Foo1'], spec;

    it 'keeps no value after undef set.';

        is_deeply [$q->cookie('foo')], [], spec;
}

{
    describe 'error';

    it 'is an attribute reader of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'error';

    it 'returns undef at init.';

        ok ! defined $q->error, spec;

    it 'keeps _die method parameter.';

        eval {
            $q->_die(500, 'Test exception');
        };
        my $err = $q->error;
        is_deeply [$err->[0], $err->[2][0]], [500, 'Test exception'], spec;
}


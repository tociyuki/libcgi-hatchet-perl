use strict;
use warnings;
use Test::More 'no_plan'; #tests => 33;
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
    describe 'error';

    it 'is an attribute reader of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'error';

    it 'returns undef at init.';

        ok ! defined $q->error, spec;

    it 'keeps _croak method parameter.';

        eval {
            $q->_croak(500, 'Test exception');
        };
        is $q->error, 'Test exception', spec;
}

{
    describe 'status';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'status';

    it 'has a default three digits value.';

        my $x = $q->status;
        ok defined $x && ! ref $x && $x =~ /\A[0-9]{3}\z/msx, spec;

    it 'changes value.';

        is $q->status(2 * $x), 2 * $x, spec;

    it 'keeps last value.';

        is $q->status, 2 * $x, spec;

    it 'has the constructor-injected value.';
    
        my $q1 = CGI::Hatchet->new(status => $x + 1);
        is $q1->status, $x + 1, spec;
}

{
    describe 'content_type';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'content_type';

    it 'returns undef at init.';

        ok ! defined $q->content_type, spec;

    it 'changes value.';

        is $q->content_type('text/html'), 'text/html', spec;

    it 'keeps last value.';

        is $q->content_type, 'text/html', spec;
    
    it 'has the constructor-injected value.';
    
        my $q1 = CGI::Hatchet->new(content_type => 'application/json');
        is $q1->content_type, 'application/json', spec;
}

{
    describe 'content_length';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'content_length';

    it 'returns undef at init.';

        ok ! defined $q->content_length, spec;

    it 'changes value.';

        is $q->content_length(256), 256, spec;

    it 'keeps last value.';

        is $q->content_length, 256, spec;
    
    it 'has the constructor-injected value.';
    
        my $q1 = CGI::Hatchet->new(content_length => 128);
        is $q1->content_length, 128, spec;
}

{
    describe 'header';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'header';

    it 'returns empty list at init.';

        is_deeply [$q->header], [], spec;

    it 'sets a value to the given key.';

        is_deeply [$q->header('Foo', 'foo0')], ['foo0'], spec;

    it 'keeps a value of the key.';

        is_deeply [$q->header('Foo')], ['foo0'], spec;

    it 'adds values into existence key.';

        is_deeply [$q->header('Foo', 'foo1', 'foo2')],
                  ['foo0', 'foo1', 'foo2'], spec;

    it 'keeps values all of the key.';

        is_deeply [$q->header('Foo')], ['foo0', 'foo1', 'foo2'], spec;

    it 'returns last value in scalar context.';

        is_deeply [scalar $q->header('Foo')], ['foo2'], spec;

    it 'replaces values with arrayref.';
    
        $q->header('Foo', 'foo0', 'foo1', 'foo2');
        $q->header('Foo', ['Foo0', 'Foo1']);
        is_deeply [$q->header('Foo')], ['Foo0', 'Foo1'], spec;

    it 'clears values in key with undef.';

        is_deeply [$q->header('Foo', undef)], ['Foo0', 'Foo1'], spec;

    it 'keeps no value after undef set.';

        is_deeply [$q->header('Foo')], [], spec;
}

{
    describe 'cookie';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'cookie';

    it 'returns empty list at init.';

        is_deeply [$q->cookie], [], spec;

    it 'sets a value to the given key.';

        is_deeply $q->cookie('foo' => 'foo0'),
                  {name => 'foo', value => 'foo0'}, spec;

    it 'keeps a value of the key.';

        is_deeply $q->cookie('foo'),
                  {name => 'foo', value => 'foo0'}, spec;

    it 'replaces value.';
    
        is_deeply $q->cookie('foo' => 'foo1'),
                  {name => 'foo', value => 'foo1'}, spec;

    it 'sets a value and optionals to the given key.';

        is_deeply $q->cookie('bar' => 'bar0', expires => 1280000000),
                  {name => 'bar', value => 'bar0', expires => 1280000000}, spec;

    it 'clears values in key with undef.';

        is_deeply $q->cookie('foo' => undef),
                  {name => 'foo', value => 'foo1'}, spec;

    it 'has only bar after delete foo.';

        is_deeply [$q->cookie], ['bar'], spec;
}

{
    describe 'body';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'body';

    it 'returns empty string at init.';

        my $x = $q->body;
        ok defined $x && $x eq q{}, spec;

    it 'changes value.';

        is $q->body('<html></html>'), '<html></html>', spec;

    it 'keeps last value.';

        is $q->body, '<html></html>', spec;
    
    it 'has the constructor-injected value.';
    
        my $q1 = CGI::Hatchet->new(body => '<html></html>');
        is $q1->body, '<html></html>', spec;
}

{
    describe 'redirect';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'redirect';

    it 'is undefinded at init.';

        ok ! defined $q->redirect, spec;

    it 'changes value.';

        is $q->redirect('/frontpage'), '/frontpage', spec;

    it 'keeps last value.';

        is $q->redirect, '/frontpage', spec;
    
    it 'drops the constructor-injected value.';
    
        my $q1 = CGI::Hatchet->new(redirect => '/frontpage');
        ok ! defined $q1->redirect, spec;
}

{
    describe 'fatals_to_browser';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'fatals_to_browser';

    it 'has a default boolean value.';

        my $x = $q->fatals_to_browser;
        ok defined $x && ! ref $x, spec;

    it 'changes value.';

        is $q->fatals_to_browser(! $x), ! $x, spec;

    it 'keeps last value.';

        is $q->fatals_to_browser, ! $x, spec;

    it 'has the constructor-injected value.';
    
        my $q1 = CGI::Hatchet->new(fatals_to_browser => 1);
        ok $q1->fatals_to_browser, spec;
}

{
    describe 'read_body';

    it 'can be done with CGI::Hatchet instance.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'read_body';
}

{
    describe 'scan_cookie';

    it 'can be done with CGI::Hatchet instance.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'scan_cookie';
        # t/02.cookie.t for detail behaviours.
}

{
    describe 'scan_formdata';

    it 'can be done with CGI::Hatchet instance.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'scan_formdata';
        # t/03.query.t and t/04.post.t for detail behaviours.
}


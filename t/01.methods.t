use strict;
use warnings;
use Test::Base tests => 184;
BEGIN {
    require 't/lib/Test/Behaviour/Spec.pm';
    Test::Behaviour::Spec->import;
}
use CGI::Hatchet;

{
    describe 'new';

    it 'is a constructor.';

        can_ok 'CGI::Hatchet', 'new';
        is ref CGI::Hatchet->new, 'CGI::Hatchet', spec;

    it 'is an instance method.';

        my $q = CGI::Hatchet->new;
        is ref $q->new, 'CGI::Hatchet', spec;
}

{
    describe 'new_response';

    it 'is a constructor.';

        can_ok 'CGI::Hatchet', 'new_response';
        is ref CGI::Hatchet->new_response, 'CGI::Hatchet', spec;

    it 'is an instance method.';

        my $q = CGI::Hatchet->new;
        is ref $q->new_response, 'CGI::Hatchet', spec;
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
    
    it 'is constructor-injectable.';

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

    it 'is constructor-injectable.';
    
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

    it 'is constructor-injectable.';
    
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

    it 'is constructor-injectable.';
    
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
    
    it 'is constructor-injectable.';
    
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

    it 'is constructor-injectable.';
    
        my $q1 = CGI::Hatchet->new(max_header => 4 * $x);
        is $q1->max_header, 4 * $x, spec;
}

{
    describe 'error';

    it 'is an attribute reader of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'error';

    it 'is undefined at init.';

        ok ! defined $q->error, spec;

    it 'keeps _croak method parameter.';

        eval {
            $q->_croak(500, 'Test exception');
        };
        is $q->error, 'Test exception', spec;

    it 'is constructor-injectable.';
    
        my $q1 = CGI::Hatchet->new(error => 'Something wrong.');
        is $q1->error, 'Something wrong.', spec;
}

{
    describe 'code';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'code';

    it 'is undefined at init.';

        ok ! defined $q->code, spec;

    it 'changes value.';

        is $q->code('200'), '200', spec;

    it 'keeps last value.';

        is $q->code, '200', spec;

    it 'is constructor-injectable.';
    
        my $q1 = CGI::Hatchet->new(code => '204');
        is $q1->code, '204', spec;
}

{
    describe 'content_type';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'content_type';

    it 'is undefined at init.';

        ok ! defined $q->content_type, spec;

    it 'changes value.';

        is $q->content_type('text/html'), 'text/html', spec;

    it 'keeps last value.';

        is $q->content_type, 'text/html', spec;
    
    it 'is constructor-injectable.';
    
        my $q1 = CGI::Hatchet->new(content_type => 'application/json');
        is $q1->content_type, 'application/json', spec;
}

{
    describe 'content_length';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'content_length';

    it 'is undefined at init.';

        ok ! defined $q->content_length, spec;

    it 'changes value.';

        is $q->content_length(256), 256, spec;

    it 'keeps last value.';

        is $q->content_length, 256, spec;
    
    it 'is constructor-injectable.';
    
        my $q1 = CGI::Hatchet->new(content_length => 128);
        is $q1->content_length, 128, spec;
}

{
    describe 'env';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'env';

    it 'has an hash reference.';

        is ref $q->env, 'HASH', spec;

    it 'changes value.';

        is_deeply $q->env({FOO => 'foo', BAR => 'bar'}),
            {FOO => 'foo', BAR => 'bar'}, spec;

    it 'keeps last value.';

        is_deeply $q->env, {FOO => 'foo', BAR => 'bar'}, spec;

    it 'is constructor-injectable.';

        my $q1 = CGI::Hatchet->new(env => {A => 'a', B => 'b'});
        is_deeply $q1->env, {A => 'a', B => 'b'}, spec;

    it 'is succeeded to responses.';

        my $r = $q->new_response;
        is_deeply $r->env, {FOO => 'foo', BAR => 'bar'}, spec;
}

{
    describe 'address';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'address';

    it 'is env REMOTE_ADDR value.';

        $q->env({REMOTE_ADDR => '192.168.0.1'});
        is $q->address, '192.168.0.1', spec;

    it 'is succeeded to responses.';

        my $r = $q->new_response;
        is $r->address, '192.168.0.1', spec;
}

{
    describe 'remote_host';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'remote_host';

    it 'is env REMOTE_HOST value.';

        $q->env({REMOTE_HOST => 'example.net'});
        is $q->remote_host, 'example.net', spec;

    it 'is succeeded to responses.';

        my $r = $q->new_response;
        is $r->remote_host, 'example.net', spec;
}

{
    describe 'protocol';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'protocol';

    it 'is env SERVER_PROTOCOL value.';

        $q->env({SERVER_PROTOCOL => 'HTTP/1.1'});
        is $q->protocol, 'HTTP/1.1', spec;

    it 'is succeeded to responses.';

        my $r = $q->new_response;
        is $r->protocol, 'HTTP/1.1', spec;
}

{
    describe 'method';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'method';

    it 'is env REQUEST_METHOD value.';

        $q->env({REQUEST_METHOD => 'PUT'});
        is $q->method, 'PUT', spec;

    it 'is succeeded to responses.';

        my $r = $q->new_response;
        is $r->method, 'PUT', spec;
}

{
    describe 'port';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'port';

    it 'is env SERVER_PORT value.';

        $q->env({SERVER_PORT => 5000});
        is $q->port, 5000, spec;

    it 'is succeeded to responses.';

        my $r = $q->new_response;
        is $r->port, 5000, spec;
}

{
    describe 'user';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'user';

    it 'is env REMOTE_USER value.';

        $q->env({REMOTE_USER => 'alice'});
        is $q->user, 'alice', spec;

    it 'is succeeded to responses.';

        my $r = $q->new_response;
        is $r->user, 'alice', spec;
}

{
    describe 'request_uri';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'request_uri';

    it 'is env REQUEST_URI value.';

        $q->env({REQUEST_URI => '/foo/bar'});
        is $q->request_uri, '/foo/bar', spec;

    it 'is succeeded to responses.';

        my $r = $q->new_response;
        is $r->request_uri, '/foo/bar', spec;
}

{
    describe 'path_info';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'path_info';

    it 'is env PATH_INFO value.';

        $q->env({PATH_INFO => '/foo/bar'});
        is $q->path_info, '/foo/bar', spec;

    it 'is succeeded to responses.';

        my $r = $q->new_response;
        is $r->path_info, '/foo/bar', spec;
}

{
    describe 'path';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'path';

    it 'is env PATH_INFO value.';

        $q->env({PATH_INFO => '/foo/bar'});
        is $q->path, '/foo/bar', spec;

    it 'is succeeded to responses.';

        my $r = $q->new_response;
        is $r->path, '/foo/bar', spec;
        
    it 'returns root for undefined or empty PATH_INFO.';
    
        $q->env({PATH_INFO => q{}});
        is $q->path, q{/}, spec;
}

{
    describe 'script_name';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'script_name';

    it 'is env SCRIPT_NAME value.';

        $q->env({SCRIPT_NAME => '/foo'});
        is $q->script_name, '/foo', spec;

    it 'is succeeded to responses.';

        my $r = $q->new_response;
        is $r->script_name, '/foo', spec;
}

{
    describe 'scheme';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'scheme';

    it 'is env psgi.url_scheme value.';

        $q->env({'psgi.url_scheme' => 'https'});
        is $q->scheme, 'https', spec;

    it 'is succeeded to responses.';

        my $r = $q->new_response;
        is $r->scheme, 'https', spec;
}

{
    describe 'secure';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'secure';

    it 'becomes false when env psgi.url_scheme is not https.';

        $q->env({'psgi.url_scheme' => 'http'});
        ok ! $q->secure, spec;

    it 'becomes true when env psgi.url_scheme is not https.';

        $q->env({'psgi.url_scheme' => 'https'});
        ok $q->secure, spec;

    it 'is succeeded to responses.';

        my $r = $q->new_response;
        ok $r->secure, spec;
}

{
    describe 'replace';

    it 'is an instance method.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'replace';
}

{
    describe 'param';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'param';

    it 'returns empty list at init.';

        is_deeply [$q->param], [], spec;

    it 'sets a value to the given key.';

        is_deeply [$q->param('Foo', 'foo0')], ['foo0'], spec;

    it 'keeps a value of the key.';

        is_deeply [$q->param('Foo')], ['foo0'], spec;

    it 'push values into existence key.';

        is_deeply [$q->param('Foo', 'foo1', 'foo2')],
                  ['foo0', 'foo1', 'foo2'], spec;

    it 'returns last value in scalar context.';

        is_deeply [scalar $q->param('Foo')], ['foo2'], spec;

    it 'returns keys in calling without name.';

        $q->param('Bar', 'bar');
        $q->param('Baz', 'baz');
        is_deeply {map { $_ => 1} $q->param},
                  {map { $_ => 1} 'Foo', 'Bar', 'Baz'}, spec;

    it 'clears values in key with undef.';

        is_deeply [$q->param('Foo', undef)], ['foo0', 'foo1', 'foo2'], spec;

    it 'keeps no value after undef set.';

        is_deeply [$q->param('Foo')], [], spec;

    it 'is replaced by pairlist.';

        $q->replace(param => ['a' => 'A', 'b' => 'B', 'a' => 'A1']);
        is_deeply {
            'keys' => {map { $_ => 1 } $q->param},
            'a' => [$q->param('a')],
            'b' => [$q->param('b')],
        }, {
            'keys' => {map { $_ => 1 } 'a', 'b'},
            'a' => ['A', 'A1'],
            'b' => ['B'],
        }, spec;

    it 'is constructor-injectable.';
    
        my $q1 = CGI::Hatchet->new(param => ['i' => 'n', 'j' => 'e', 'c' => 't']);
        is_deeply {
            'keys' => {map { $_ => 1 } $q1->param},
            'i' => [$q1->param('i')],
            'j' => [$q1->param('j')],
            'c' => [$q1->param('c')],
        }, {
            'keys' => {map { $_ => 1 } 'i', 'j', 'c'},
            'i' => ['n'],
            'j' => ['e'],
            'c' => ['t'],
        }, spec;
}

{
    describe 'upload';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'upload';

    it 'returns empty list at init.';

        is_deeply [$q->upload], [], spec;

    it 'sets a value to the given key.';

        is_deeply [$q->upload('Foo', 'foo0')], ['foo0'], spec;

    it 'keeps a value of the key.';

        is_deeply [$q->upload('Foo')], ['foo0'], spec;

    it 'push values into existence key.';

        is_deeply [$q->upload('Foo', 'foo1', 'foo2')],
                  ['foo0', 'foo1', 'foo2'], spec;

    it 'returns last value in scalar context.';

        is_deeply [scalar $q->upload('Foo')], ['foo2'], spec;

    it 'returns keys in calling without name.';

        $q->upload('Bar', 'bar');
        $q->upload('Baz', 'baz');
        is_deeply {map { $_ => 1} $q->upload},
                  {map { $_ => 1} 'Foo', 'Bar', 'Baz'}, spec;

    it 'clears values in key with undef.';

        is_deeply [$q->upload('Foo', undef)], ['foo0', 'foo1', 'foo2'], spec;

    it 'keeps no value after undef set.';

        is_deeply [$q->upload('Foo')], [], spec;

    it 'is replaced by pairlist.';

        $q->replace(upload => ['a' => 'A', 'b' => 'B', 'a' => 'A1']);
        is_deeply {
            'keys' => {map { $_ => 1 } $q->upload},
            'a' => [$q->upload('a')],
            'b' => [$q->upload('b')],
        }, {
            'keys' => {map { $_ => 1 } 'a', 'b'},
            'a' => ['A', 'A1'],
            'b' => ['B'],
        }, spec;

    it 'is constructor-injectable.';
    
        my $q1 = CGI::Hatchet->new(upload => ['i' => 'n', 'j' => 'e', 'c' => 't']);
        is_deeply {
            'keys' => {map { $_ => 1 } $q1->upload},
            'i' => [$q1->upload('i')],
            'j' => [$q1->upload('j')],
            'c' => [$q1->upload('c')],
        }, {
            'keys' => {map { $_ => 1 } 'i', 'j', 'c'},
            'i' => ['n'],
            'j' => ['e'],
            'c' => ['t'],
        }, spec;
}

{
    describe 'request_cookie';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'request_cookie';

    it 'returns empty list at init.';

        is_deeply [$q->request_cookie], [], spec;

    it 'sets a value to the given key.';

        is_deeply [$q->request_cookie('Foo', 'foo0')], ['foo0'], spec;

    it 'keeps a value of the key.';

        is_deeply [$q->request_cookie('Foo')], ['foo0'], spec;

    it 'push values into existence key.';

        is_deeply [$q->request_cookie('Foo', 'foo1', 'foo2')],
                  ['foo0', 'foo1', 'foo2'], spec;

    it 'returns last value in scalar context.';

        is_deeply [scalar $q->request_cookie('Foo')], ['foo2'], spec;

    it 'returns keys in calling without name.';

        $q->request_cookie('Bar', 'bar');
        $q->request_cookie('Baz', 'baz');
        is_deeply {map { $_ => 1} $q->request_cookie},
                  {map { $_ => 1} 'Foo', 'Bar', 'Baz'}, spec;

    it 'clears values in key with undef.';

        is_deeply [$q->request_cookie('Foo', undef)], ['foo0', 'foo1', 'foo2'], spec;

    it 'keeps no value after undef set.';

        is_deeply [$q->request_cookie('Foo')], [], spec;

    it 'is replaced by pairlist.';

        $q->replace(request_cookie => ('a' => 'A', 'b' => 'B', 'a' => 'A1'));
        is_deeply {
            'keys' => {map { $_ => 1 } $q->request_cookie},
            'a' => [$q->request_cookie('a')],
            'b' => [$q->request_cookie('b')],
        }, {
            'keys' => {map { $_ => 1 } 'a', 'b'},
            'a' => ['A', 'A1'],
            'b' => ['B'],
        }, spec;

    it 'is constructor-injectable.';
    
        my $q1 = CGI::Hatchet->new(request_cookie => [
            'i' => 'n', 'j' => 'e', 'c' => 't']);
        is_deeply {
            'keys' => {map { $_ => 1 } $q1->request_cookie},
            'i' => [$q1->request_cookie('i')],
            'j' => [$q1->request_cookie('j')],
            'c' => [$q1->request_cookie('c')],
        }, {
            'keys' => {map { $_ => 1 } 'i', 'j', 'c'},
            'i' => ['n'],
            'j' => ['e'],
            'c' => ['t'],
        }, spec;
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

    it 'replaces existence key.';

        is_deeply [$q->header('Foo', 'foo1', 'foo2')],
                  ['foo1'], spec;

    it 'returns last value in scalar context.';

        is_deeply [scalar $q->header('Foo')], ['foo1'], spec;

    it 'clears values in key with undef.';

        is_deeply [$q->header('Foo', undef)], ['foo1'], spec;

    it 'keeps no value after undef set.';

        is_deeply [$q->header('Foo')], [], spec;

    it 'sets a value to the Set-Cookie.';

        is_deeply [$q->header('Set-Cookie', 'c0=A')], ['c0=A'], spec;

    it 'adds values existence Set-Cookie.';

        is_deeply [$q->header('Set-Cookie', 'c1=B', 'c2=C')],
                  ['c0=A', 'c1=B', 'c2=C'], spec;

    it 'replaces Set-Cookie values with arrayref.';

        $q->header('Set-Cookie', ['C0=a', 'C1=b']);
        is_deeply [$q->header('Set-Cookie')], ['C0=a', 'C1=b'], spec;

    it 'clears values in key with undef.';

        is_deeply [$q->header('Set-Cookie', undef)], ['C0=a', 'C1=b'], spec;

    it 'keeps no value after undef set.';

        is_deeply [$q->header('Set-Cookie')], [], spec;

    it 'is replaced by pairlist.';

        $q->replace(header => (
                'A' => 'a0', 'A' => 'a1',
                'Set-Cookie' => 'u=', 'Set-Cookie' => 'k=v'));
        is_deeply {
            'keys' => {map { $_ => 1 } $q->header},
            'A' => [$q->header('A')],
            'Set-Cookie' => [$q->header('Set-Cookie')],
        }, {
            'keys' => {map { $_ => 1 } 'A', 'Set-Cookie'},
            'A' => ['a1'],
            'Set-Cookie' => ['u=', 'k=v'],
        }, spec;

    it 'is constructor-injectable.';
    
        my $q1 = CGI::Hatchet->new(header => [
                'A' => 'a0', 'A' => 'a1',
                'Set-Cookie' => 'u=', 'Set-Cookie' => 'k=v']);
        is_deeply {
            'keys' => {map { $_ => 1 } $q1->header},
            'A' => [$q1->header('A')],
            'Set-Cookie' => [$q1->header('Set-Cookie')],
        }, {
            'keys' => {map { $_ => 1 } 'A', 'Set-Cookie'},
            'A' => ['a1'],
            'Set-Cookie' => ['u=', 'k=v'],
        }, spec;
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

    it 'sets a content by hash.';

        is_deeply $q->cookie('foo' => {name => 'foo0', value => ''}),
                  {name => 'foo0', value => ''}, spec;

    it 'is replaced by pairlist.';

        $q->replace(cookie => [
                'a' => 'a0', 'b' => {name => 'b', value => 'b0'}]);
        is_deeply {
            'keys' => {map { $_ => 1 } $q->cookie},
            'a' => [$q->cookie('a')],
            'b' => [$q->cookie('b')],
        }, {
            'keys' => {map { $_ => 1 } 'a', 'b'},
            'a' => [{name => 'a', value => 'a0'}],
            'b' => [{name => 'b', value => 'b0'}],
        }, spec;

    it 'is constructor-injectable.';
    
        my $q1 = CGI::Hatchet->new(cookie => [
                'a' => 'a0', 'b' => {name => 'b', value => 'b0'}]);
        is_deeply {
            'keys' => {map { $_ => 1 } $q1->cookie},
            'a' => [$q1->cookie('a')],
            'b' => [$q1->cookie('b')],
        }, {
            'keys' => {map { $_ => 1 } 'a', 'b'},
            'a' => [{name => 'a', value => 'a0'}],
            'b' => [{name => 'b', value => 'b0'}],
        }, spec;
}

{
    describe 'body';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'body';

    it 'is undefined at init.';

        ok ! defined $q->body, spec;

    it 'changes value.';

        is $q->body('<html></html>'), '<html></html>', spec;

    it 'keeps last value.';

        is $q->body, '<html></html>', spec;
    
    it 'is constructor-injectable.';
    
        my $q1 = CGI::Hatchet->new(body => '<html></html>');
        is $q1->body, '<html></html>', spec;
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

    it 'is constructor-injectable.';
    
        my $q1 = CGI::Hatchet->new(fatals_to_browser => 1);
        ok $q1->fatals_to_browser, spec;
}

{
    describe 'error_page_builder';

    it 'is an attribute of CGI::Hatchet.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'error_page_builder';

    it 'is undefined on init.';

        ok ! defined $q->error_page_builder, spec;

    it 'changes value.';

        my $builder = sub{};
        is $q->error_page_builder($builder), $builder, spec;

    it 'keeps last value.';

        is $q->error_page_builder, $builder, spec;

    it 'is constructor-injectable.';
    
        my $q1 = CGI::Hatchet->new(error_page_builder => $builder);
        is $q1->error_page_builder, $builder, spec;
}

{
    describe 'read_body';

    it 'is an instance method.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'read_body';
}

{
    describe 'scan_header';

    it 'is an instance method.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'scan_header';
        # t/05.scan_header.t for detail behaviours.
}

{
    describe 'scan_cookie';

    it 'is an instance method.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'scan_cookie';
        # t/02.scan_cookie.t for detail behaviours.
}

{
    describe 'scan_formdata';

    it 'is an instance method.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'scan_formdata';
        # t/03.query.t and t/04.post.t for detail behaviours.
}

{
    describe 'redirect';

    it 'is an instance method.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'redirect';

    it 'changes location.';

        $q->redirect('/frontpage');
        ok $q->header('Location') eq '/frontpage' && $q->code eq '303', spec; 

    it 'changes location and code.';

        $q->redirect('/frontpage', '301');
        ok $q->header('Location') eq '/frontpage' && $q->code eq '301', spec; 
}

{
    describe 'finalize_cookie';

    it 'is an instance method.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'finalize_cookie';
        # t/10.set_cookie.t for detail behaviours.
}

{
    describe 'normalize';

    it 'is an instance method.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'normalize';
}

{
    describe 'finalize';

    it 'is an instance method.';

        my $q = CGI::Hatchet->new;
        can_ok $q, 'finalize';
}


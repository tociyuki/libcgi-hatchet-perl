use strict;
use warnings;
use Test::More tests => 33;
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


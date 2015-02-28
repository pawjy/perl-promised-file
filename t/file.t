use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Promised::File;

test {
  my $c = shift;
  my $f = Promised::File->new_from_path ('hoge.txt');
  isa_ok $f, 'Promised::File';
  done $c;
} n => 1, name => 'new_from_path';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data/1.txt'));
  $f->read_byte_string->then (sub {
    my $string = $_[0];
    test {
      is $string, "\xFEab\x80\x00aa";
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'read_byte_string';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data/symlink1.txt'));
  $f->read_byte_string->then (sub {
    my $string = $_[0];
    test {
      is $string, "\xFEab\x80\x00aa";
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'read_byte_string symlink';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data/symlinkd1/1.txt'));
  $f->read_byte_string->then (sub {
    my $string = $_[0];
    test {
      is $string, "\xFEab\x80\x00aa";
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'read_byte_string in symlink dir';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data/not/found.txt'));
  $f->read_byte_string->then (sub {
    my $string = $_[0];
    test {
      ok 0;
    } $c;
  }, sub {
    my $result = $_[0];
    test {
      ok $result, $result;
    } $c;
  })->then (sub { done $c; undef $c });
} n => 1, name => 'read_byte_string file not found';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data'));
  $f->read_byte_string->then (sub {
    my $string = $_[0];
    test {
      ok 0;
    } $c;
  }, sub {
    my $result = $_[0];
    test {
      ok $result, $result;
    } $c;
  })->then (sub { done $c; undef $c });
} n => 1, name => 'read_byte_string directory';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data/1.txt'));
  $f->read_char_string->then (sub {
    my $string = $_[0];
    test {
      is $string, "\x{FFFD}ab\x{FFFD}\x00aa";
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'read_char_string';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data/2.txt'));
  $f->read_char_string->then (sub {
    my $string = $_[0];
    test {
      is $string, "\x{4E00}\x{4E8C}";
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'read_char_string';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data/not/found.txt'));
  $f->read_char_string->then (sub {
    my $string = $_[0];
    test {
      ok 0;
    } $c;
  }, sub {
    my $result = $_[0];
    test {
      ok $result, $result;
    } $c;
  })->then (sub { done $c; undef $c });
} n => 1, name => 'read_char_string file not found';

run_tests;

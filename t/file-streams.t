use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Promised::File;
use Promised::Flow;

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data/1.txt'));
  my $stream = $f->read_bytes;
  test {
    isa_ok $stream, 'ReadableStream';
  } $c;
  my $reader = $stream->get_reader ('byob');
  my $bytes = '';
  my $read; $read = sub {
    return $reader->read (DataView->new (ArrayBuffer->new (2)))->then (sub {
      return if $_[0]->{done};
      $bytes .= $_[0]->{value}->manakai_to_string;
      return $read->();
    });
  }; # $read
  return (promised_cleanup { undef $read } $read->())->then (sub {
    test {
      is $bytes, "\xFEab\x80\x00aa";
    } $c;
    done $c;
    undef $c;
  });
} n => 2, name => 'read_bytes';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data/1.txt'));
  my $stream = $f->read_bytes;
  test {
    isa_ok $stream, 'ReadableStream';
  } $c;
  my $reader = $stream->get_reader ('byob');
  my $bytes = '';
  my $read; $read = sub {
    return $reader->read (DataView->new (ArrayBuffer->new (2)))->then (sub {
      return if $_[0]->{done};
      $bytes .= $_[0]->{value}->manakai_to_string;
      return $read->();
    });
  }; # $read
  $read->();
  return (promised_cleanup { undef $read } $read->())->then (sub {
    test {
      is $bytes, "\xFEab\x80\x00aa";
    } $c;
    done $c;
    undef $c;
  });
} n => 2, name => 'read_bytes';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data/1.txt'));
  my $stream = $f->read_bytes;
  test {
    isa_ok $stream, 'ReadableStream';
  } $c;
  my $reader = $stream->get_reader ('byob');
  my $bytes = '';
  my $read; $read = sub {
    return $reader->read (DataView->new (ArrayBuffer->new (2)))->then (sub {
      return if $_[0]->{done};
      $bytes .= $_[0]->{value}->manakai_to_string;
      $reader->cancel;
      return $read->();
    });
  }; # $read
  return (promised_cleanup { undef $read } $read->())->then (sub {
    test {
      is $bytes, "\xFEa", "Can be 0xFE only in theory, but unlikely";
    } $c;
    done $c;
    undef $c;
  });
} n => 2, name => 'read_bytes cancelled';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data/symlink1.txt'));
  my $stream = $f->read_bytes;
  my $reader = $stream->get_reader ('byob');
  my $bytes = '';
  my $read; $read = sub {
    return $reader->read (DataView->new (ArrayBuffer->new (2)))->then (sub {
      return if $_[0]->{done};
      $bytes .= $_[0]->{value}->manakai_to_string;
      return $read->();
    });
  }; # $read
  return (promised_cleanup { undef $read } $read->())->then (sub {
    test {
      is $bytes, "\xFEab\x80\x00aa";
    } $c;
    done $c;
    undef $c;
  });
} n => 1, name => 'read_bytes symlink';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data/symlinkd1/1.txt'));
  my $stream = $f->read_bytes;
  my $reader = $stream->get_reader ('byob');
  my $bytes = '';
  my $read; $read = sub {
    return $reader->read (DataView->new (ArrayBuffer->new (2)))->then (sub {
      return if $_[0]->{done};
      $bytes .= $_[0]->{value}->manakai_to_string;
      return $read->();
    });
  }; # $read
  return (promised_cleanup { undef $read } $read->())->then (sub {
    test {
      is $bytes, "\xFEab\x80\x00aa";
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'read_bytes in symlink dir';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data/not/found.txt'));
  my $rs = $f->read_bytes;
  test {
    isa_ok $rs, 'ReadableStream';
  } $c;
  my $reader = $rs->get_reader ('byob');
  $reader->read (DataView->new (ArrayBuffer->new (1)))->then (sub {
    test {
      ok 0;
    } $c;
  }, sub {
    my $result = $_[0];
    test {
      is $result->name, 'Perl I/O error', $result;
      ok $result->errno;
      ok $result->message;
      is $result->file_name, __FILE__;
      is $result->line_number, __LINE__-16;
    } $c;
  })->then (sub { done $c; undef $c });
} n => 6, name => 'read_bytes file not found';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data'));
  my $rs = $f->read_bytes;
  test {
    isa_ok $rs, 'ReadableStream';
  } $c;
  my $reader = $rs->get_reader ('byob');
  $reader->read (DataView->new (ArrayBuffer->new (1)))->then (sub {
    test {
      ok 0;
    } $c;
  }, sub {
    my $result = $_[0];
    test {
      is $result->name, 'Perl I/O error', $result;
      ok $result->errno;
      ok $result->message;
      is $result->file_name, __FILE__;
      is $result->line_number, __LINE__-16;
    } $c;
  })->then (sub { done $c; undef $c });
} n => 6, name => 'read_bytes directory';

run_tests;

=head1 LICENSE

Copyright 2015-2017 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

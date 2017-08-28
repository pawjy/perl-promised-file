use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use ArrayBuffer;
use DataView;
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

my $TempPath = q{/tmp};

test {
  my $c = shift;
  my $p = "$TempPath/hoge." . rand;
  my $f = Promised::File->new_from_path ($p);
  my $ws = $f->write_bytes;
  test {
    isa_ok $ws, 'WritableStream';
  } $c;
  my $writer = $ws->get_writer;
  $writer->close->then (sub {
    my $g = Promised::File->new_from_path ($p);
    $g->read_byte_string->then (sub {
      my $data = $_[0];
      test {
        is $data, '';
      } $c;
    });
  }, sub { test { ok 0 } $c; warn $_[0] })->then (sub {
    return $f->remove_tree;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 2, name => 'write_bytes empty';

test {
  my $c = shift;
  my $p = "$TempPath/hoge." . rand;
  my $f = Promised::File->new_from_path ($p);
  my $ws = $f->write_bytes;
  my $writer = $ws->get_writer;
  $writer->write (DataView->new (ArrayBuffer->new_from_scalarref (\"ab \x00\xFE\x8a\x91aX ")));
  $writer->close->then (sub {
    my $g = Promised::File->new_from_path ($p);
    $g->read_byte_string->then (sub {
      my $data = $_[0];
      test {
        is $data, "ab \x00\xFE\x8a\x91aX ";
      } $c;
    });
  }, sub { test { ok 0 } $c; warn $_[0] })->then (sub {
    return $f->remove_tree;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'write_bytes';

test {
  my $c = shift;
  my $p = "$TempPath/hoge." . rand;
  my $f = Promised::File->new_from_path ($p);
  $f->write_byte_string ("ab hoge aaa ")->then (sub {
    my $ws = $f->write_bytes;
    my $writer = $ws->get_writer;
    $writer->write (DataView->new (ArrayBuffer->new_from_scalarref (\"ab \x00\xFE\x8a\x91aX ")));
    return $writer->close;
  })->then (sub {
    my $g = Promised::File->new_from_path ($p);
    $g->read_byte_string->then (sub {
      my $data = $_[0];
      test {
        is $data, "ab \x00\xFE\x8a\x91aX ";
      } $c;
    });
  }, sub { test { ok 0 } $c; warn $_[0] })->then (sub {
    return $f->remove_tree;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'write_bytes existing';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data'));
  my $ws = $f->write_bytes;
  my $writer = $ws->get_writer;
  $writer->write (DataView->new (ArrayBuffer->new_from_scalarref (\"ab hoge aaa ")))->catch (sub { });
  $writer->close->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $error = $_[0];
    test {
      is $error->name, 'Perl I/O error', $error;
      ok $error->errno;
      ok $error->message;
      is $error->file_name, __FILE__;
      is $error->line_number, __LINE__-12;
    } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 5, name => 'write_bytes existing directory 1';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data'));
  my $ws = $f->write_bytes;
  my $writer = $ws->get_writer;
  $writer->write (DataView->new (ArrayBuffer->new_from_scalarref (\"ab hoge aaa ")))->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $error = $_[0];
    test {
      is $error->name, 'Perl I/O error', $error;
      ok $error->errno;
      ok $error->message;
      is $error->file_name, __FILE__;
      is $error->line_number, __LINE__-11;
    } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 5, name => 'write_bytes existing directory 2';

test {
  my $c = shift;
  my $p = "$TempPath/hoge." . rand;
  my $f0 = Promised::File->new_from_path ($p);
  $f0->write_byte_string ('abc')->then (sub {
    my $f = Promised::File->new_from_path ("$p/foo");
    my $ws = $f->write_bytes;
    my $writer = $ws->get_writer;
    return $writer->write (DataView->new (ArrayBuffer->new_from_scalarref (\"ab \x00\xFE\x8a\x91aX ")));
  })->catch (sub {
    my $error = $_[0];
    test {
      ok $error, $error;
    } $c;
    my $g = Promised::File->new_from_path ($p);
    return $g->read_byte_string;
  })->then (sub {
    my $data = $_[0];
    test {
      is $data, "abc";
    } $c;
  }, sub { test { ok 0 } $c; warn $_[0] })->then (sub {
    return $f0->remove_tree;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 2, name => 'write_bytes mkdir failure';

test {
  my $c = shift;
  my $p = "$TempPath/hoge." . rand;
  my $f = Promised::File->new_from_path ($p);
  my $ws = $f->write_bytes;
  my $writer = $ws->get_writer;
  $writer->write (DataView->new (ArrayBuffer->new_from_scalarref (\"ab \x00\xFE\x8a\x91aX ")));
  my $v = DataView->new (ArrayBuffer->new (1));
  $v->buffer->_transfer; # detach
  $writer->write ($v)->catch (sub {
    my $error = $_[0];
    test {
      is $error->name, 'TypeError', $error;
    } $c;
    my $g = Promised::File->new_from_path ($p);
    $g->read_byte_string->then (sub {
      my $data = $_[0];
      test {
        is $data, "ab \x00\xFE\x8a\x91aX ";
      } $c;
    });
  }, sub { test { ok 0 } $c; warn $_[0] })->then (sub {
    return $f->remove_tree;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 2, name => 'write_bytes arraybuffer detached';

test {
  my $c = shift;
  my $p = "$TempPath/hoge." . rand;
  my $f = Promised::File->new_from_path ($p);
  my $ws = $f->write_bytes;
  my $writer = $ws->get_writer;
  $writer->write (DataView->new (ArrayBuffer->new_from_scalarref (\"ab \x00\xFE\x8a\x91aX ")));
  $writer->write ("abc")->catch (sub {
    my $error = $_[0];
    test {
      ok $error, $error;
    } $c;
    my $g = Promised::File->new_from_path ($p);
    $g->read_byte_string->then (sub {
      my $data = $_[0];
      test {
        is $data, "ab \x00\xFE\x8a\x91aX ";
      } $c;
    });
  }, sub { test { ok 0 } $c; warn $_[0] })->then (sub {
    return $f->remove_tree;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 2, name => 'write_bytes not arraybufferview';

test {
  my $c = shift;
  my $p = "$TempPath/hoge." . rand;
  my $f = Promised::File->new_from_path ($p);
  my $ws = $f->write_bytes;
  my $writer = $ws->get_writer;
  $writer->write (DataView->new (ArrayBuffer->new_from_scalarref (\"ab \x00\xFE\x8a\x91aX ")))->then (sub {
    $writer->abort;
  });
  $writer->closed->catch (sub {
    my $error = $_[0];
    test {
      ok $error, $error;
    } $c;
    my $g = Promised::File->new_from_path ($p);
    $g->read_byte_string->then (sub {
      my $data = $_[0];
      test {
        is $data, "ab \x00\xFE\x8a\x91aX ";
      } $c;
    });
  }, sub { test { ok 0 } $c; warn $_[0] })->then (sub {
    return $f->remove_tree;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 2, name => 'write_bytes aborted';

test {
  my $c = shift;
  my $p = "$TempPath/hoge." . rand;
  my $f = Promised::File->new_from_path ($p);
  my $ws = $f->write_bytes;
  my $writer = $ws->get_writer;
  my $data = '';
  my $value = '';
  promised_wait_until {
    my $v = 't3aqgawg' x (1024*10);
    $data .= $v;
    return $writer->write (DataView->new (ArrayBuffer->new_from_scalarref (\$v)))->then (sub {
      if (length $data > 1024*1024) {
        $writer->close;
        return 1;
      } else {
        return 0;
      }
    });
  } interval => 0.001;
  $writer->closed->then (sub {
    my $rs = $f->read_bytes;
    my $reader = $rs->get_reader ('byob');
    my $read; $read = sub {
      return $reader->read (DataView->new (ArrayBuffer->new (1024)))->then (sub {
        return if $_[0]->{done};
        $value .= $_[0]->{value}->manakai_to_string;
        return $read->();
      });
    }; # $read
    return promised_cleanup { undef $read } $read->();
  })->then (sub {
    test {
      is -s $p, length $data, length $data;
      is $value, $data;
    } $c;
  }, sub { test { ok 0 } $c; warn $_[0] })->then (sub {
    return $f->remove_tree;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 2, name => 'read and write large';

run_tests;

=head1 LICENSE

Copyright 2015-2017 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

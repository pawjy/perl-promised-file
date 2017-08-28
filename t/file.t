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

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data/1.txt'));
  $f->stat->then (sub {
    my $stat = $_[0];
    test {
      isa_ok $stat, 'File::stat';
      ok -e $stat;
      ok -f $stat;
      ok not -d $stat;
      ok not -l $stat;
      done $c;
      undef $c;
    } $c;
  });
} n => 5, name => 'stat normal file';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data/symlink1.txt'));
  $f->stat->then (sub {
    my $stat = $_[0];
    test {
      isa_ok $stat, 'File::stat';
      ok -e $stat;
      ok -f $stat;
      ok not -d $stat;
      ok not -l $stat;
      done $c;
      undef $c;
    } $c;
  });
} n => 5, name => 'stat symlink';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data/'));
  $f->stat->then (sub {
    my $stat = $_[0];
    test {
      isa_ok $stat, 'File::stat';
      ok -e $stat;
      ok not -f $stat;
      ok -d $stat;
      ok not -l $stat;
      done $c;
      undef $c;
    } $c;
  });
} n => 5, name => 'stat directory';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data/not/found.txt'));
  $f->stat->catch (sub {
    my $error = $_[0];
    test {
      ok $error;
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'stat not found';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data/1.txt'));
  $f->lstat->then (sub {
    my $stat = $_[0];
    test {
      isa_ok $stat, 'File::stat';
      ok -e $stat;
      ok -f $stat;
      ok not -d $stat;
      ok not -l $stat;
      done $c;
      undef $c;
    } $c;
  });
} n => 5, name => 'lstat normal file';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data/symlink1.txt'));
  $f->lstat->then (sub {
    my $stat = $_[0];
    test {
      isa_ok $stat, 'File::stat';
      ok -e $stat;
      ok not -f $stat;
      ok not -d $stat;
      ok -l $stat;
      done $c;
      undef $c;
    } $c;
  });
} n => 5, name => 'lstat symlink';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data/'));
  $f->lstat->then (sub {
    my $stat = $_[0];
    test {
      isa_ok $stat, 'File::stat';
      ok -e $stat;
      ok not -f $stat;
      ok -d $stat;
      ok not -l $stat;
      done $c;
      undef $c;
    } $c;
  });
} n => 5, name => 'lstat directory';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data/not/found.txt'));
  $f->lstat->catch (sub {
    my $error = $_[0];
    test {
      ok $error;
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'lstat not found';

for (
  ['t_deps/data/not/found.txt', 0, 0, 0, 0],
  ['t_deps/data/1.txt',         1, 0, 0, 0],
  ['t_deps/data',               0, 1, 0, 1],
  ['t_deps/data/symlink1.txt',  1, 0, 1, 1],
  ['t_deps/data/symlinkd1',     0, 1, 1, 1],
  ['t_deps/data/3.txt',         1, 0, 0, 1],
) {
  my ($path, $is_file, $is_directory, $is_symlink, $is_executable) = @$_;
  test {
    my $c = shift;
    my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ($path));
    Promise->all ([
      $f->is_file->then (sub {
        my $value = $_[0];
        test { is !!$value, !!$is_file, 'is_file' } $c;
      }),
      $f->is_directory->then (sub {
        my $value = $_[0];
        test { is !!$value, !!$is_directory, 'is_directory' } $c;
      }),
      $f->is_symlink->then (sub {
        my $value = $_[0];
        test { is !!$value, !!$is_symlink, 'is_symlink' } $c;
      }),
      $f->is_executable->then (sub {
        my $value = $_[0];
        test { is !!$value, !!$is_executable, 'is_executable' } $c;
      }),
    ])->then (sub { done $c; undef $c });
  } n => 4, name => [$path];
}

my $TempPath = q{/tmp};

test {
  my $c = shift;
  my $p = "$TempPath/hoge" . rand;
  my $f = Promised::File->new_from_path ($p);
  $f->mkpath->then (sub {
    my $g = Promised::File->new_from_path ($p);
    return $g->is_directory->then (sub {
      my $result = $_[0];
      test {
        ok $result;
      } $c;
    });
  })->then (sub {
    return Promised::File->new_from_path ($p)->remove_tree;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'mkpath 1';

test {
  my $c = shift;
  my $p = "$TempPath/hoge" . rand;
  my $f = Promised::File->new_from_path ($p);
  $f->mkpath->then (sub {
    my $g = Promised::File->new_from_path ("$p/fuga");
    return $g->mkpath->then (sub {
      my $h = Promised::File->new_from_path ("$p/fuga");
      return $h->is_directory->then (sub {
        my $result = $_[0];
        test {
          ok $result;
        } $c;
      });
    });
  })->then (sub {
    return Promised::File->new_from_path ($p)->remove_tree;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'mkpath 2';

test {
  my $c = shift;
  my $p = "$TempPath/hoge" . rand;
  my $f = Promised::File->new_from_path ($p);
  $f->mkpath->then (sub {
    my $g = Promised::File->new_from_path ($p);
    return $g->mkpath->then (sub {
      my $h = Promised::File->new_from_path ($p);
      return $h->is_directory->then (sub {
        my $result = $_[0];
        test {
          ok $result;
        } $c;
      });
    });
  })->then (sub {
    return Promised::File->new_from_path ($p)->remove_tree;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'mkpath 0';

test {
  my $c = shift;
  my $p = "$TempPath/hoge" . rand;
  my $f = Promised::File->new_from_path ("$p///");
  $f->mkpath->then (sub {
    my $g = Promised::File->new_from_path ($p);
    return $g->is_directory->then (sub {
      my $result = $_[0];
      test {
        ok $result;
      } $c;
    });
  })->then (sub {
    return Promised::File->new_from_path ($p)->remove_tree;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'mkpath 1 trailing slashes';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data/2.txt'));
  $f->mkpath->then (sub {
    test {
      ok 0;
    } $c;
  }, sub {
    my $error = $_[0];
    test {
      ok $error;
    } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'mkpath conflict with file';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data/2.txt/hoge'));
  $f->mkpath->then (sub {
    test {
      ok 0;
    } $c;
  }, sub {
    my $error = $_[0];
    test {
      ok $error;
    } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'mkpath conflict with file';

test {
  my $c = shift;
  my $p = "$TempPath/hoge" . rand;
  my $f = Promised::File->new_from_path ($p);
  $f->mkpath->then (sub {
    my $g = Promised::File->new_from_path ($p);
    return $g->remove_tree->then (sub {
      my $h = Promised::File->new_from_path ($p);
      return $h->is_directory->then (sub {
        my $result = $_[0];
        test {
          ok not $result;
        } $c;
      });
    });
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'remove_tree directory';

test {
  my $c = shift;
  my $p = "$TempPath/hoge" . rand;
  my $f = Promised::File->new_from_path ("$p/fuga");
  $f->mkpath->then (sub {
    my $g = Promised::File->new_from_path ($p);
    return $g->remove_tree->then (sub {
      my $h = Promised::File->new_from_path ($p);
      return $h->is_directory->then (sub {
        my $result = $_[0];
        test {
          ok not $result;
        } $c;
      });
    });
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'remove_tree directory with directory';

test {
  my $c = shift;
  my $p = "$TempPath/hoge" . rand;
  my $g = Promised::File->new_from_path ($p);
  return $g->remove_tree->then (sub {
    my $h = Promised::File->new_from_path ($p);
    return $h->is_directory->then (sub {
      my $result = $_[0];
      test {
        ok not $result;
      } $c;
    });
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'remove_tree directory not found';

test {
  my $c = shift;
  my $p = "$TempPath/hoge." . rand;
  my $f = Promised::File->new_from_path ($p);
  $f->write_byte_string ('')->then (sub {
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
} n => 1, name => 'write_byte_string empty';

test {
  my $c = shift;
  my $p = "$TempPath/hoge." . rand;
  my $f = Promised::File->new_from_path ($p);
  $f->write_byte_string ("ab \x00\xFE\x8a\x91aX ")->then (sub {
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
} n => 1, name => 'write_byte_string';

test {
  my $c = shift;
  my $p = "$TempPath/hoge." . rand;
  my $f = Promised::File->new_from_path ($p);
  $f->write_byte_string ("ab hoge aaa ")->then (sub {
    return $f->write_byte_string ("ab \x00\xFE\x8a\x91aX ");
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
} n => 1, name => 'write_byte_string existing';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data'));
  $f->write_byte_string ("ab hoge aaa ")->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $error = $_[0];
    test {
      ok $error;
    } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'write_byte_string existing directory';

test {
  my $c = shift;
  my $p = "$TempPath/hoge." . rand;
  my $f = Promised::File->new_from_path ($p);
  $f->write_char_string ("ab \x00\xFE\x8a\x91aX ")->then (sub {
    my $g = Promised::File->new_from_path ($p);
    $g->read_byte_string->then (sub {
      my $data = $_[0];
      test {
        is $data, "ab \x00\xC3\xBE\xC2\x8A\xC2\x91aX ";
      } $c;
    });
  }, sub { test { ok 0 } $c; warn $_[0] })->then (sub {
    return $f->remove_tree;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'write_char_string';

test {
  my $c = shift;
  my $p = "$TempPath/hoge." . rand;
  my $f = Promised::File->new_from_path ($p);
  $f->write_char_string ("\x{5000}")->then (sub {
    my $g = Promised::File->new_from_path ($p);
    $g->read_byte_string->then (sub {
      my $data = $_[0];
      test {
        is $data, "\xE5\x80\x80";
      } $c;
    });
  }, sub { test { ok 0 } $c; warn $_[0] })->then (sub {
    return $f->remove_tree;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'write_char_string';

test {
  my $c = shift;
  my $f = Promised::File->new_from_path (path (__FILE__)->parent->parent->child ('t_deps/data'));
  $f->write_char_string ("ab hoge aaa ")->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $error = $_[0];
    test {
      ok $error;
    } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'write_char_string existing directory';

test {
  my $c = shift;
  my $p = "$TempPath/hoge." . rand;
  my $f = Promised::File->new_from_path ("$p/a/b/c.txt");
  $f->write_char_string ("\x{5000}")->then (sub {
    my $g = Promised::File->new_from_path ("$p/a/b/c.txt");
    $g->read_byte_string->then (sub {
      my $data = $_[0];
      test {
        is $data, "\xE5\x80\x80";
      } $c;
    });
  }, sub { test { ok 0 } $c; warn $_[0] })->then (sub {
    return $f->remove_tree;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'write_char_string new directory';

test {
  my $c = shift;
  my $p = "$TempPath/hoge" . rand;
  my $f = Promised::File->new_from_path ($p);
  $f->mkpath->then (sub {
    return $f->get_child_names;
  })->then (sub {
    my $result = $_[0];
    test {
      is ref $result, 'ARRAY';
      is 0+@$result, 0;
    } $c;
  })->then (sub {
    return $f->remove_tree;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 2, name => 'get_child_names empty';

test {
  my $c = shift;
  my $p = "$TempPath/hoge" . rand;
  my $f = Promised::File->new_from_path ($p);
  Promise->all ([
    Promised::File->new_from_path ("$p/abc")->write_byte_string (''),
    Promised::File->new_from_path ("$p/def.txt")->write_byte_string (''),
  ])->then (sub {
    return $f->get_child_names;
  })->then (sub {
    my $result = $_[0];
    test {
      is ref $result, 'ARRAY';
      is 0+@$result, 2;
      my $names = {map { $_ => 1 } @$result};
      ok $names->{'abc'};
      ok $names->{'def.txt'};
    } $c;
  })->then (sub {
    return $f->remove_tree;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 4, name => 'get_child_names not empty';

test {
  my $c = shift;
  my $p = "$TempPath/hoge" . rand;
  my $f = Promised::File->new_from_path ($p);
  Promise->all ([
    Promised::File->new_from_path ("$p/\x{4e00}a")->write_byte_string (''),
  ])->then (sub {
    return $f->get_child_names;
  })->then (sub {
    my $result = $_[0];
    test {
      is ref $result, 'ARRAY';
      is 0+@$result, 1;
      my $names = {map { $_ => 1 } @$result};
      ok $names->{"\xE4\xB8\x80a"};
    } $c;
  })->then (sub {
    return $f->remove_tree;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 3, name => 'get_child_names non-ASCII';

test {
  my $c = shift;
  my $p = "$TempPath/hoge" . rand;
  my $f = Promised::File->new_from_path ($p);
  Promise->all ([
    Promised::File->new_from_path ("$p/abc")->write_byte_string (''),
    Promised::File->new_from_path ("$p/def/foo.txt")->write_byte_string (''),
  ])->then (sub {
    return $f->get_child_names;
  })->then (sub {
    my $result = $_[0];
    test {
      is ref $result, 'ARRAY';
      is 0+@$result, 2;
      my $names = {map { $_ => 1 } @$result};
      ok $names->{'abc'};
      ok $names->{'def'};
    } $c;
  })->then (sub {
    return $f->remove_tree;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 4, name => 'get_child_names directory';

test {
  my $c = shift;
  my $p = "$TempPath/hoge" . rand;
  my $f = Promised::File->new_from_path ($p);
  return $f->get_child_names->catch (sub {
    my $error = $_[0];
    test {
      is $error->name, 'Perl I/O error', $error;
      ok $error->errno;
      ok $error->message;
      is $error->file_name, __FILE__;
      is $error->line_number, __LINE__+7;
    } $c;
  })->then (sub {
    return $f->remove_tree;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 5, name => 'get_child_names not found';

test {
  my $c = shift;
  my $p = "$TempPath/hoge" . rand;
  my $f = Promised::File->new_from_path ($p);
  return $f->write_byte_string ('')->then (sub {
    return $f->get_child_names;
  })->catch (sub {
    my $error = $_[0];
    test {
      is $error->name, 'Perl I/O error', $error;
      ok $error->errno;
      ok $error->message;
      is $error->file_name, __FILE__;
      is $error->line_number, __LINE__-8;
    } $c;
  })->then (sub {
    return $f->remove_tree;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 5, name => 'get_child_names file';

run_tests;

=head1 LICENSE

Copyright 2015-2017 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

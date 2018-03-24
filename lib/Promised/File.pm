package Promised::File;
use strict;
use warnings;
our $VERSION = '3.0';
use Carp;
use AnyEvent::IO qw(:DEFAULT :flags);
use AnyEvent::Util;
use Promise;
use Promised::Flow;

push our @CARP_NOT, qw(
  Streams::IOError ReadableStream WritableStream
  TypedArray DataView Promise
);

eval { require Web::Encoding };
if (Web::Encoding->can ('encode_web_utf8')) {
  *encode_utf8 = Web::Encoding->can ('encode_web_utf8');
  *decode_utf8 = Web::Encoding->can ('decode_web_utf8');
} else {
  require Encode;
  *encode_utf8 = sub ($) { return Encode::encode ("utf-8", $_[0]) };
  *decode_utf8 = sub ($) { return Encode::decode ("utf-8", $_[0]) };
}

sub new_from_path ($$) {
  my $path = $_[1];
  croak "No argument" unless defined $path;
  unless ($path =~ m{^/}) {
    require Cwd;
    $path = Cwd::getcwd () . '/' . $path;
  }
  $path = encode_utf8 ($path);
  return bless {path => $path}, $_[0];
} # new_from_path

sub stat ($) {
  my $self = $_[0];
  return Promise->resolve ($self->{stat}) if defined $self->{stat};
  return Promise->new (sub {
    my ($ok, $ng) = @_;
    aio_stat $self->{path}, sub {
      return $ng->("|$self->{path}|: $!") unless @_;
      require File::stat;
      $ok->($self->{stat} = File::stat::stat (\*_));
    };
  });
} # stat

sub lstat ($) {
  my $self = $_[0];
  return Promise->resolve ($self->{lstat}) if defined $self->{lstat};
  return Promise->new (sub {
    my ($ok, $ng) = @_;
    aio_lstat $self->{path}, sub {
      return $ng->("|$self->{path}|: $!") unless @_;
      require File::stat;
      $ok->($self->{lstat} = File::stat::stat (\*_));
    };
  });
} # lstat

sub is_file ($) {
  return $_[0]->stat->then (sub {
    return -f $_[0];
  }, sub {
    return 0;
  });
} # is_file

sub is_directory ($) {
  return $_[0]->stat->then (sub {
    return -d $_[0];
  }, sub {
    return 0;
  });
} # is_directory

sub is_symlink ($) {
  return $_[0]->lstat->then (sub {
    return -l $_[0];
  }, sub {
    return 0;
  });
} # is_symlink

sub is_executable ($) {
  return $_[0]->lstat->then (sub {
    return -x $_[0];
  }, sub {
    return 0;
  });
} # is_executable

sub mkpath ($) {
  my $self = $_[0];
  return $self->is_directory->then (sub {
    if ($_[0]) {
      return;
    } else {
      my $path = $self->{path};
      $path =~ s{/+[^/]*\z}{};
      return __PACKAGE__->new_from_path ($path)->mkpath->then (sub {
        return Promise->new (sub {
          my ($ok, $ng) = @_;
          aio_mkdir $self->{path}, 0755, sub {
            return $ng->("|$self->{path}|: $!") unless @_;
            delete $self->{stat};
            delete $self->{lstat};
            $ok->();
          };
        })->catch (sub {
          my $error = $_[0];
          delete $self->{stat};
          delete $self->{lstat};
          return $self->is_directory->then (sub {
            if ($_[0]) {
              return;
            } else {
              die $error;
            }
          });
        });
      });
    }
  });
} # mkpath

sub remove_tree ($) {
  my $self = $_[0];
  return $self->stat->then (sub {
    if (-e $_[0]) {
      return Promise->new (sub {
        my ($ok, $ng) = @_;
        my $path = $self->{path};
        fork_call {
          my $err;
          my $args = {error => \$err, safe => 1};
          require File::Path;
          File::Path::remove_tree ($path, $args);
          if (defined $err and @$err) {
            my ($file, $msg) = %{$err->[0]};
            die "$file: $msg\n";
          }
          return 1;
        } sub {
          return $ng->($@ || $!) unless @_;
          delete $self->{stat};
          delete $self->{lstat};
          $ok->();
        };
      });
    }
    return;
  }, sub { return });
} # remove_tree

sub get_child_names ($) {
  my $self = $_[0];
  return Promise->new (sub {
    my ($ok, $ng) = @_;
    aio_readdir $self->{path}, sub {
      return $ng->([0+$!, "".$!]) unless @_;
      $ok->($_[0]);
    };
  })->catch (sub {
    require Streams::IOError;
    die Streams::IOError->new_from_errno_and_message (@{$_[0]});
  });
} # get_child_names

sub read_bytes ($) {
  my $self = $_[0];
  require ArrayBuffer;
  require DataView;
  require ReadableStream;
  my $fh;
  my $rs = ReadableStream->new ({
    type => 'bytes',
    start => sub {
      my $rc = $_[1];
      return Promise->new (sub {
        my ($ok, $ng) = @_;
        aio_open $self->{path}, O_RDONLY, 0, sub {
          return $ng->([0+$!, "".$!]) unless @_;
          $fh = $_[0];
          $ok->();
        };
      })->catch (sub {
        die Streams::IOError->new_from_errno_and_message (@{$_[0]});
      });
    }, # start
    auto_allocate_chunk_size => 1024*2,
    pull => sub {
      my $rc = $_[1];
      my $run; $run = sub {
        my $req = $rc->byob_request;
        return unless defined $req;

        my $length = $req->view->byte_length;
        return unless $length;
        return Promise->new (sub {
          my ($ok, $ng) = @_;
          return $ok->(undef) unless defined $fh;
          aio_read $fh, $length, sub {
            return $ng->([0+$!, ''.$!]) unless @_;
            $ok->(undef) unless length $_[0];
            $ok->(DataView->new (ArrayBuffer->new_from_scalarref (\($_[0]))));
          };
        })->then (sub {
          if (defined $_[0]) {
            $rc->enqueue ($_[0]); # will string-copy!
            return $run->();
          } else { # eof
            $rc->close;
            $req->respond (0);
            undef $fh;
          }
        }, sub {
          die Streams::IOError->new_from_errno_and_message (@{$_[0]});
        });
      }; # $run
      return promised_cleanup { undef $run } $run->()->catch (sub {
        undef $fh;
        die $_[0];
      });
    }, # pull
    cancel => sub {
      undef $fh;
    }, # cancel
  });
  return $rs;
} # read_bytes

sub read_byte_string ($) {
  my $self = $_[0];
  return Promise->new (sub {
    my ($ok, $ng) = @_;
    aio_load $self->{path}, sub {
      return $ng->("|$self->{path}|: $!") unless @_;
      $ok->($_[0]);
    };
  });
} # read_byte_string

sub read_char_string ($) {
  return $_[0]->read_byte_string->then (sub {
    return decode_utf8 ($_[0]);
  });
} # read_char_string

sub write_bytes ($) {
  my $self = $_[0];
  my $path = $self->{path};
  $path =~ s{[^/]*\z}{};
  require WritableStream;
  require DataView;
  my $fh;
  return WritableStream->new ({
    start => sub {
      return __PACKAGE__->new_from_path ($path)->mkpath->then (sub {
        return Promise->new (sub {
          my ($ok, $ng) = @_;
          aio_open $self->{path}, O_WRONLY | O_TRUNC | O_CREAT, 0644, sub {
            return $ng->([0+$!, "".$!]) unless @_;
            $fh = $_[0];
            delete $self->{stat};
            delete $self->{lstat};
            $ok->();
          };
        })->catch (sub {
          die Streams::IOError->new_from_errno_and_message (@{$_[0]});
        });
      });
    }, # start
    write => sub {
      my $view = $_[1];
      return Promise->resolve->then (sub {
        die "The argument is not an ArrayBufferView"
            unless UNIVERSAL::isa ($view, 'ArrayBufferView');
        my $dv = DataView->new
            ($view->buffer, $view->byte_offset, $view->byte_length); # or throw
        my $write; $write = sub {
          return Promise->resolve unless $dv->byte_length;
          return Promise->new (sub {
            my ($ok, $ng) = @_;
            aio_write $fh, $dv->manakai_to_string, sub {
              return $ng->([0+$!, "".$!]) unless @_;
              return $ok->($_[0]); # length
            };
          })->then (sub {
            $dv = DataView->new
                ($dv->buffer, $dv->byte_offset + $_[0], $dv->byte_length - $_[0]); # or throw
          }, sub {
            die Streams::IOError->new_from_errno_and_message (@{$_[0]});
          });
          return $write->();
        }; # $write
        return promised_cleanup { undef $write } $write->();
      })->catch (sub {
        my $error = $_[0];
        return Promise->new (sub {
          aio_close $fh, $_[0];
        })->then (sub {
          die $error;
        });
      });
    }, # write
    close => sub {
      return Promise->new (sub {
        aio_close $fh, $_[0];
      });
    }, # close
    abort => sub {
      return Promise->new (sub {
        aio_close $fh, $_[0];
      });
    }, # abort
  });
} # write_bytes

sub write_byte_string ($$) {
  my $self = $_[0];
  my $sref = \($_[1]);
  my $path = $self->{path};
  $path =~ s{[^/]*\z}{};
  return __PACKAGE__->new_from_path ($path)->mkpath->then (sub {
    my $fh;
    return Promise->new (sub {
      my ($ok, $ng) = @_;
      aio_open $self->{path}, O_WRONLY | O_TRUNC | O_CREAT, 0644, sub {
        return $ng->("|$self->{path}|: $!") unless @_;
        $fh = $_[0];
        delete $self->{stat};
        delete $self->{lstat};
        $ok->();
      };
    })->then (sub {
      my $write; $write = sub {
        return Promise->new (sub {
          my ($ok, $ng) = @_;
          aio_write $fh, $$sref, sub {
            return $ng->("|$self->{path}|: $!") unless @_;
            my $length = $_[0];
            if ($length < length $$sref) {
              my $s = substr $$sref, $length;
              $sref = \$s;
              $ok->($write->());
            } else {
              $ok->();
            }
          };
        });
      }; # $write
      return $write->()->then (sub {
        return Promise->new (sub {
          my ($ok, $ng) = @_;
          aio_close $fh, sub { $ok->() };
        });
      }, sub {
        my $error = $_[0];
        return Promise->new (sub {
          my ($ok, $ng) = @_;
          aio_close $fh, sub { $ok->() };
        })->then (sub { return $error });
      });
    });
  });
} # write_byte_string

sub write_char_string ($$) {
  return $_[0]->write_byte_string (encode_utf8 ($_[1]));
} # write_char_string

1;

=head1 LICENSE

Copyright 2015-2017 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

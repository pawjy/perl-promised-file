package Promised::File;
use strict;
use warnings;
our $VERSION = '1.0';
use Encode;
use AnyEvent::IO qw(:DEFAULT :flags);
use AnyEvent::Util;
use Promise;

sub new_from_path ($$) {
  my $path = $_[1];
  unless ($path =~ m{^/}) {
    require Cwd;
    $path = Cwd::getcwd () . '/' . $path;
  }
  $path = encode 'utf-8', $path;
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
          my $args = {err => \$err, safe => 1};
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
    return decode 'utf-8', $_[0];
  });
} # read_char_string

1;

=head1 LICENSE

Copyright 2015 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

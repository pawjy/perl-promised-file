package Promised::File;
use strict;
use warnings;
our $VERSION = '1.0';
use Encode;
use AnyEvent::IO qw(:DEFAULT :flags);
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

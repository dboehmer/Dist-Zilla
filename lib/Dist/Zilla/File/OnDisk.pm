package Dist::Zilla::File::OnDisk;
# ABSTRACT: a file that comes from your filesystem
use Moose;
with 'Dist::Zilla::Role::File';

has content => (
  is  => 'rw',
  isa => 'Str',
  lazy => 1,
  default => sub { shift->_read_file },
);

has _original_name => (
  is  => 'ro',
  isa => 'Str',
  init_arg => undef,
);

sub BUILD {
  my ($self) = @_;
  $self->{_original_name} = $self->name;
}

sub _read_file {
  my ($self) = @_;

  my $fname = $self->_original_name;
  open my $fh, '<', $fname or die "can't open $fname for reading: $!";
  my $content = do { local $/; <$fh> };
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

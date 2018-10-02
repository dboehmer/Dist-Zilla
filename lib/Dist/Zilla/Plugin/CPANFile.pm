package Dist::Zilla::Plugin::CPANFile;
# ABSTRACT: produce a cpanfile prereqs file

use Moose;
with 'Dist::Zilla::Role::FileGatherer';

use namespace::autoclean;

use Dist::Zilla::File::FromCode;

=head1 SYNOPSIS

    # dist.ini
    [CPANFile]

=head1 DESCRIPTION

This plugin will add a F<cpanfile> file to the distribution.

=attr filename

If given, parameter allows you to specify an alternate name for the generated
file.  It defaults, of course, to F<cpanfile>.

    # dist.ini
    [CPANFile]
    filename = dzil-generated-cpanfile

=attr comment

=attr comments

This parameter allows to insert comments at the top of F<cpanfile>. Each
parameter prepends its value as one line to the file. The lines are
inserted in the same order as the parameters occur in F<dist.ini>.

The value might include leading whitespace and a literal C<#> character
as comment indicator. Otherwise a C<#> is inserted after any leading
whitespace.

C<comment> is an alias for C<comments>.

=head1 SEE ALSO

=for :list
* L<Module::CPANfile>
* L<Carton>
* L<cpanm>

=cut

has comments => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  default => sub { [] },
);

has filename => (
  is  => 'ro',
  isa => 'Str',
  default => 'cpanfile',
);

sub mvp_aliases { { comment => 'comments' } }
sub mvp_multivalue_args { qw(comments) }

sub _hunkify_hunky_hunk_hunks {
  my ($self, $indent, $type, $req) = @_;

  my $str = '';
  for my $module (sort $req->required_modules) {
    my $vstr = $req->requirements_for_module($module);
    $str .= qq{$type "$module" => "$vstr";\n};
  }
  $str =~ s/^/'  ' x $indent/egm;
  return $str;
}

sub gather_files {
  my ($self, $arg) = @_;

  my $comments = $self->comments;
  my $zilla = $self->zilla;

  my $file  = Dist::Zilla::File::FromCode->new({
    name => $self->filename,
    code => sub {
      my $prereqs = $zilla->prereqs;

      my @types  = qw(requires recommends suggests conflicts);
      my @phases = qw(runtime build test configure develop);

      my $str = '';

      for my $comment (@$comments) {
        $comment =~ s/ ^ (\s*) (?=[^#]) /# $1/gmx;
        $str .= $comment . "\n";
      }

      for my $phase (@phases) {
        for my $type (@types) {
          my $req = $prereqs->requirements_for($phase, $type);
          next unless $req->required_modules;
          $str .= qq[\non '$phase' => sub {\n] unless $phase eq 'runtime';
          $str .= $self->_hunkify_hunky_hunk_hunks(
            ($phase eq 'runtime' ? 0 : 1),
            $type,
            $req,
          );
          $str .= qq[};\n]                     unless $phase eq 'runtime';
        }
      }

      return $str;
    },
  });

  $self->add_file($file);
  return;
}

__PACKAGE__->meta->make_immutable;
1;

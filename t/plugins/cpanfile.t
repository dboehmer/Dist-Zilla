use strict;
use warnings;

use Test::More;
use Test::DZil;

is cpanfile('build/cpanfile') => <<INI, "cpanfile contains requirements";
requires "strict" => "0";
requires "warnings" => "0";
INI

ok cpanfile('build/otherfile' => { filename => 'otherfile' }),
  "non-default filename";

like cpanfile('build/cpanfile' => { comment => ["foobar"] }) => qr/^# foobar\n/,
  "simple comment";

like cpanfile('build/cpanfile' => { comment => ["#foobar"] }) => qr/^#foobar\n/,
  "comment with literal '#'";

like cpanfile('build/cpanfile' => { comment => [ "foo", "bar" ] }) =>
  qr/^# foo\n# bar\n/,
  "multiline comment";

done_testing;

sub cpanfile {
  my $filename = shift;

  my $opts = @_ ? [ map { (CPANFile => $_) } @_ ] : 'CPANFile';

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZ1' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(qw< GatherDir AutoPrereqs  >, $opts),
      },
    },
  );

  $tzil->build;

  return $tzil->slurp_file($filename);
}

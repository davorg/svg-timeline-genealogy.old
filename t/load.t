use Test::More;

BEGIN {
  use_ok 'Genealogy::Chart::SVG';
}

ok(my $tl = Genealogy::Chart::SVG->new);
isa_ok($tl, 'Genealogy::Chart::SVG');

done_testing;

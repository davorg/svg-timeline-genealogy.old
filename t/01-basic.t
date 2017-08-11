
use Test::More;

use SVG::Timeline::Genealogy;

my $tl = SVG::Timeline::Genealogy->new;

$tl->person({
  id => 1,
  name => 'Mr Example',
  birth => 1900,
  death => 2000,
});

ok(my $chart = $tl->xmlify);

done_testing();

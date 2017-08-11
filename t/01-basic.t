
use Test::More;

use Genealogy::Chart::SVG;

my $gcs = Genealogy::Chart::SVG->new;

$gcs->person({
  id => 1,
  name => 'Mr Example',
  birth => 1900,
  death => 2000,
});

ok(my $chart = $gcs->xmlify);

done_testing();

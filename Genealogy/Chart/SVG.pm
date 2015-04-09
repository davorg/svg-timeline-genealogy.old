package Genealogy::Chart::SVG;

use strict;
use warnings;

use Moose;

use Time::Piece;
use File::Basename;
use SVG;

has svg => (
  is         => 'ro',
  isa        => 'SVG',
  lazy_build => 1,
  handles    => [qw[xmlify line text rect cdata]],
);

sub _build_svg {
  my $self = shift;
  return SVG->new(
    width  => ( $self->years * $self->pixels_per_year ),
    height => $self->height,
  );
}

# Array of colours - one for each generation.
has colours => (
  is         => 'ro',
  isa        => 'ArrayRef',
  lazy_build => 1,
);

sub _build_colours {
  no warnings 'qw';    # I know what I'm doing here!
  return [
    map { "rgb($_)" }
      qw(
      0
      255,127,127
      127,255,127
      127,127,255
      255,255,127
      255,127,255
      127,255,255
      )
  ];
}

# The height of a bar in pixels
has bar_height => (
  is      => 'ro',
  isa     => 'Int',
  default => 18,
);

# The number of years the chart will cover
has years => (
  is      => 'ro',
  isa     => 'Int',
  default => 200,
);

# The number of horizontal pixels to use for each year
has pixels_per_year => (
  is      => 'ro',
  isa     => 'Int',
  default => 5,
);

# The height of the chart in pixels
has height => (
  is      => 'ro',
  isa     => 'Int',
  default => 1500,
);

# The left-hand extent of the chart.
# N.B. Should probably rename to 'latest_year' or something like that.
has left => (
  is      => 'ro',
  isa     => 'Int',
  default => localtime->year,
);

# The colour that the decade lines are drawn on the chart
has decade_line_colour => (
  is      => 'ro',
  isa     => 'Str',
  default => 'rgb(127,127,127)',
);

# The colour that the bars are outlined
has bar_outline_colour => (
  is      => 'ro',
  isa     => 'Str',
  default => 'rgb(0,0,0)',
);

sub BUILD {
  my $self = shift;

  my $curr_y = $self->left;
  my $x      = 0;

  # Draw the decade lines
  while ( $curr_y > ( $self->left - $self->years ) ) {
    unless ( $curr_y % 10 ) {
      $self->line(
        x1           => $x,
        y1           => 0,
        x2           => $x,
        y2           => $self->height,
        stroke       => $self->decade_line_colour,
        stroke_width => 1
      );
      $self->text(
        x           => $x + 1,
        y           => 12,
        'font-size' => $self->bar_height / 2
      )->cdata($curr_y);
    }
    $curr_y--;
    $x += $self->pixels_per_year;
  }

  return $self;
}

# Produce a bar containing the details of one person.
sub person {
  my $self = shift;
  my ( $n, $name, $b, $d ) = @_;

  my $gen = gen($n);

  my $until = $d || $self->left;

  # TODO: I think that $p is pointless here
  my $p = $self->rect(
    x              => ( $self->left - $until ) * $self->pixels_per_year,
    y              => ( $self->height * y_pos($n) ) - ( $self->bar_height / 2 ),
    width          => ( $until - $b ) * $self->pixels_per_year,
    height         => $self->bar_height,
    fill           => $self->colours->[$gen],
    stroke         => $self->bar_outline_colour,
    'stroke-width' => 1
  );

  my $text = "$n: $name ($b - ";
  $text .= $d if $d;
  $text .= ')';
  $self->text(
    x => ( $self->left - $until + 2 ) * $self->pixels_per_year,
    y => ( $self->height * y_pos($n) ) + ( $self->bar_height / 2 ) - 3,
    'font-size' => $self->bar_height - 4
  )->cdata($text);
}

# Get the generation number from an Ahnentafel number.
# Person 1 is in generation 1
# Persons 2 & 3 are Person 1's parents and are in generation 2
# Persons 4, 5, 6 & 7 are Person 1's grandparents and are in generation 3
# etc ...
sub gen {
  die unless @_;

  return int log( $_[0] ) / log(2) + 1;
}

# Calculate the y-position for a given person number.
# Not entirely sure how I did this, to be honest. Need to reverse engineer
# it and document it!
sub y_pos {
  die unless @_;

  # TODO: int?
  return num( $_[0] ) / den( $_[0] );
}

sub num {
  my $num = shift;

  return 2 * ( $num - den($num) / 2 ) + 1;
}

sub den {
  my $num = shift;

  return 2**( gen($num) );
}

1;

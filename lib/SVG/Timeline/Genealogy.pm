=head1 NAME

SVG::Timeline::Genealogy

=head1 DESCRIPTION

Perl extension for drawing Genealogical charts using SVG.

=cut

package SVG::Timeline::Genealogy;

use strict;
use warnings;

use 5.010;
our $VERSION = '0.0.1';

use Moose;

use Time::Piece;
use File::Basename;
use Carp;
use SVG;

use Genealogy::Ahnentafel;

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
  default => 250,
);

# The number of years between vertical grid lines
has years_per_grid => (
  is      => 'ro',
  isa     => 'Int',
  default => 10, # One decade by default
);

# The number of horizontal pixels to use for each year
has pixels_per_year => (
  is      => 'ro',
  isa     => 'Int',
  default => 5,
);

# Padding at the top and bottom of each person bar (in pixels)
has bar_padding => (
  is      => 'ro',
  isa     => 'Int',
  default => 2,
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

=head1 METHODS

=head2 BUILD

=cut

sub BUILD {
  my $self = shift;

  my $curr_year = $self->left;
  my $x      = 0;

  # Draw the decade lines
  while ( $curr_year > ( $self->left - $self->years ) ) {
    unless ( $curr_year % $self->years_per_grid ) {
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
      )->cdata($curr_year);
    }
    $curr_year--;
    $x += $self->pixels_per_year;
  }

  return $self;
}

=head2 person

=cut

# Produce a bar containing the details of one person.
sub person {
  my $self = shift;
  my ($person) = @_;
  my ( $n, $name, $b, $d ) = @_;

  my $gen = ahnen($person->{id})->generation;

  my $until = $person->{death} || $self->left;

  $self->rect(
    x              => ( $self->left - $until ) * $self->pixels_per_year,
    y              => ( $self->height * y_pos($person->{id}) ) - ( $self->bar_height / 2 ),
    width          => ( $until - $person->{birth} ) * $self->pixels_per_year,
    height         => $self->bar_height,
    fill           => $self->colours->[$gen],
    stroke         => $self->bar_outline_colour,
    'stroke-width' => 1
  );

  my $text = "$person->{id}: $person->{name} ($person->{birth} - ";
  $text .= $person->{death} if $person->{death};
  $text .= ')';
  $self->text(
    x => ( $self->left - $until + 1 ) * $self->pixels_per_year,
    y => ( $self->height * y_pos($person->{id}) )
       + ( $self->bar_height / 2 )
       - ( 2 * $self->bar_padding ),
    'font-size' => $self->bar_height - $self->bar_padding,
  )->cdata($text);

  return;
}

# Calculate the y-position for a given person number.
# This is a decimal fraction of how far down the chart the person
# should appear.
#
# The 1st generation appears 1/2 down the page.
# The 2nd generation appears 1/4 and 3/4 down the page.
# The 3rd generation appears 1/8, 3/8, 5/8 and 7/8 down the page.
# etc ...

=head2 y_pos

=cut

sub y_pos {
  croak 'No generation passed to y_pos()' unless @_;

  # TODO: int?
  return num( $_[0] ) / den( $_[0] );
}

=head2 num

=cut

# No idea how this works. But it does.
sub num {
  my $num = shift;

  return 2 * ( $num - den($num) / 2 ) + 1;
}

# The denominator of the calculation of how far down the chart the given
# person should appear.
# For the 1st generation, it is 2.
# For the 2nd generation, it is 4.
# For the 3rd generation, it is 8.
# etc ...
#
# So convert the persons number to a generation number, and calculate
# 2 ** the generation number.

=head2 den

=cut

sub den {
  my $num = shift;

  return 2**( ahnen($num)->generation );
}

1;

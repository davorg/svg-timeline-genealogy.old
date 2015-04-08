package Genealogy::Chart::SVG;

use strict;
use warnings;

use Moose;

use Time::Piece;
use File::Basename;
use SVG;

use constant BAR_HEIGHT => 18;
use constant YEARS => 200;
use constant PX_PER_YR => 5;
use constant HEIGHT => 1500;

my @colours = do {
  no warnings 'qw'; # I know what I'm doing here!
  map { "rgb($_)" }
    qw[
      0
      255,127,127
      127,255,127
      127,127,255
      255,255,127
      255,127,255
      127,255,255
    ];
};

my $grey  = 'rgb(127,127,127)';
my $black = 'rgb(0,0,0)';

my $left = localtime->year;
my $right = $left - YEARS;

has svg => (
  is  => 'ro',
  isa => 'SVG',
  lazy_build => 1,
  handles => [ qw[xmlify line text rect cdata] ],
);

sub _build_svg {
  return SVG->new(width => (YEARS * PX_PER_YR), height => HEIGHT);
}

sub BUILD {
  my $self = shift;

  my $curr_y = $left;
  my $x = 0;
  # Draw the decade lines
  while ($curr_y > ($left - YEARS)) {
    unless ($curr_y % 10) {
      $self->line(x1 => $x, y1 => 0, x2 => $x, y2 => HEIGHT,
                  stroke => $grey, stroke_width => 1);
      $self->text(x => $x + 1, y => 12,
                 'font-size' => BAR_HEIGHT / 2)->cdata($curr_y);
    }
    $curr_y--;
    $x += PX_PER_YR;
  }

  return $self;
}

sub person {
  my $self = shift;
  my ($n, $name, $b, $d) = @_;

  my $gen = gen($n);

  my $until = $d || $left;

  my $p = $self->rect(
            x => ($left - $until) * PX_PER_YR,
            y => (HEIGHT * y_pos($n)) - (BAR_HEIGHT / 2),
            width => ($until - $b) * PX_PER_YR,
            height => BAR_HEIGHT,
            fill => $colours[$gen],
            stroke => $black,
            'stroke-width' => 1
          );

  my $text = "$n: $name ($b - ";
  $text .= $d if $d;
  $text .= ')';
  $self->text(x => ($left - $until + 2) * PX_PER_YR,
              y => (HEIGHT * y_pos($n)) + (BAR_HEIGHT / 2) - 3,
              'font-size' => BAR_HEIGHT - 4)->cdata($text);
}

sub gen {
  die unless @_;

  return int log($_[0])/log(2) + 1;
}

sub y_pos {
  die unless @_;

  return num($_[0]) / den($_[0]);
}

sub num {
  my $num = shift;

  return 2 * ($num - den($num)/2) + 1;
}

sub den {
  my $num = shift;

  return 2 ** (gen($num));
}


1;
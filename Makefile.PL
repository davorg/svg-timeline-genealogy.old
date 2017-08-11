use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'Genealogy::Chart::SVG',
  VERSION_FROM => 'lib/Genealogy/Chart/SVG.pm',
  LICENSE      => 'perl_5',
  MIN_PERL_VERSION => '5.10.0',

  BUILD_REQUIRES => {
    'Test::More' => 0,
    'ExtUtils::MakeMaker' => 0,
    SVG => 0,
    Moose => 0,
  },
  PREREQ_PM => {
    SVG => 0,
    Moose => 0,
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'git://github.com/davorg/genealogy-chart-svg.git',
        web => 'https://github.com/davorg/genealgoy-chart-svge',
      },
    },
  },
  EXE_FILES => [ 'bin/chart' ],
);

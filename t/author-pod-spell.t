
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

# generated by Dist::Zilla::Plugin::Test::PodSpelling
use strict;
use warnings;
use Test::More;

eval "use Test::Spelling 0.12; use Pod::Wordlist::hanekomu; 1" or die $@;


add_stopwords(<DATA>);
all_pod_files_spelling_ok('bin', 'lib');
__DATA__
SubmittingPatches
wordlist
Caleb
Cushing
Randy
Stauner
Marcel
Gruenauer
Harley
Pig
lib
Dist
Zilla
Plugin
PodSpellingTests
Test
PodSpelling

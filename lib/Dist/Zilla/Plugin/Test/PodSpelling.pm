package Dist::Zilla::Plugin::Test::PodSpelling;
use 5.010;
use strict;
use warnings;

our $VERSION = '2.006001'; # VERSION

use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with (
	'Dist::Zilla::Role::TextTemplate',
	'Dist::Zilla::Role::FileFinderUser' => {
		default_finders => [ ':InstallModules' ],
	},
);

sub mvp_multivalue_args { return ( qw( stopwords directories ) ) }

has wordlist => (
	is      => 'ro',
	isa     => 'Str',
	default => 'Pod::Wordlist::hanekomu',    # default to original
);

has spell_cmd => (
	is      => 'ro',
	isa     => 'Str',
	default => '',                           # default to original
);

has stopwords => (
	is      => 'ro',
	isa     => 'ArrayRef[Str]',
	traits  => [ 'Array' ],
	default => sub { [] },                   # default to original
	handles => {
		push_stopwords => 'push',
		uniq_stopwords => 'uniq',
		no_stopwords   => 'is_empty',
	}
);

has directories => (
	isa     => 'ArrayRef[Str]',
	traits  => [ 'Array' ],
	is      => 'ro',
	default => sub { [] },                   # default to original
	handles => {
		no_directories => 'is_empty',
		print_directories => [ join => ' ' ],
	}
);

sub add_stopword {
	my ( $self, $data ) = @_;

	$self->log_debug( 'attempting stopwords extraction from: ' . $data );
	# words must be greater than 2 characters
	my ( $word ) = $data =~ /(\p{Word}{2,})/xms;

	# log won't like an undef
	return unless $word;

	$self->log_debug( 'add stopword: ' . $word );

	$self->push_stopwords( $word );
	return;
}

around add_file => sub {
	my ($orig, $self, $file) = @_;
	my ($set_spell_cmd, $add_stopwords, $stopwords);
	if ($self->spell_cmd) {
		$set_spell_cmd = sprintf "set_spell_cmd('%s');", $self->spell_cmd;
	}

	foreach my $holder ( split( /\s/xms, join( ' ',
			@{ $self->zilla->authors },
			$self->zilla->copyright_holder,
			@{ $self->zilla->distmeta->{x_contributors} || [] },
		))
	) {
		$self->add_stopword( $holder );
	}

	foreach my $file ( @{ $self->found_files } ) {
		# many of my stopwords are part of a filename
		$self->log_debug( 'splitting filenames for more words' );

		foreach my $name ( split( '/', $file->name ) ) {
			$self->add_stopword( $name );
		}
	}

	unless ( $self->no_stopwords ) {
		$add_stopwords = 'add_stopwords(<DATA>);';
		$stopwords = join "\n", '__DATA__', $self->uniq_stopwords;
	}

	$self->$orig(
		Dist::Zilla::File::InMemory->new(
			{   name    => $file->name,
				content => $self->fill_in_string(
					$file->content,
					{
						name          => __PACKAGE__,
						version       => __PACKAGE__->VERSION
							|| 'bootstrapped version',
						wordlist      => \$self->wordlist,
						set_spell_cmd => \$set_spell_cmd,
						add_stopwords => \$add_stopwords,
						stopwords     => \$stopwords,
						directories   => \$self->print_directories,
					},
				),
			}
		),
	);
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

# ABSTRACT: Author tests for POD spelling

=pod

=head1 NAME

Dist::Zilla::Plugin::Test::PodSpelling - Author tests for POD spelling

=head1 VERSION

version 2.006001

=head1 SYNOPSIS

In C<dist.ini>:

	[Test::PodSpelling]

or:

	[Test::PodSpelling]
	directories = docs
	wordlist = Pod::Wordlist
	spell_cmd = aspell list
	stopwords = CPAN
	stopwords = github
	stopwords = stopwords
	stopwords = wordlist

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing
the following file:

  xt/author/pod-spell.t - a standard Test::Spelling test

=head1 ATTRIBUTES

=head2 directories

Additional directories you wish to search for POD spell checking purposes.
C<bin> and C<lib> are set by default.

=head2 wordlist

The module name of a word list you wish to use that works with
L<Test::Spelling>.

Defaults to L<Pod::Wordlist::hanekomu>.

=head2 spell_cmd

If C<spell_cmd> is set then C<set_spell_cmd( your_spell_command );> is
added to the test file to allow for custom spell check programs.

Defaults to nothing.

=head2 stopwords

If stopwords is set then C<add_stopwords( E<lt>DATAE<gt> )> is added
to the test file and the words are added after the C<__DATA__>
section.

C<stopwords> can appear multiple times, one word per line.

Normally no stopwords are added by default, but author names appearing in
C<dist.ini> are automatically added as stopwords so you don't have to add them
manually just because they might appear in the C<AUTHORS> section of the
generated POD document. The same goes for contributors listed under the
'x_contributors' field on your distributions META file.

=head1 METHODS

=head2 add_stopword

Called to add stopwords to the stopwords array. It is used to determine if
automagically detected words are valid and print out debug logging for the
process.

=for Pod::Coverage mvp_multivalue_args

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/xenoterracide/dist-zilla-plugin-test-podspelling/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

=over 4

=item *

Caleb Cushing <xenoterracide@gmail.com>

=item *

Randy Stauner <rwstauner@cpan.org>

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Harley Pig <harleypig@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__DATA__
___[ xt/author/pod-spell.t ]___
use strict;
use warnings;
use Test::More;

# generated by {{ $name }} {{ $version }}
eval "use Test::Spelling 0.12; use {{ $wordlist }}; 1" or die $@;

{{ $set_spell_cmd }}
{{ $add_stopwords }}
all_pod_files_spelling_ok( qw( bin lib {{ $directories }} ) );
{{ $stopwords }}

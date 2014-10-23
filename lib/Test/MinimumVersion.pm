use 5.006;
use strict;
use warnings;
package Test::MinimumVersion;
BEGIN {
  $Test::MinimumVersion::VERSION = '0.101080';
}
use base 'Exporter';
# ABSTRACT: does your code require newer perl than you think?


use File::Find::Rule;
use File::Find::Rule::Perl;
use Perl::MinimumVersion 1.20; # accuracy
use YAML::Tiny 1.40; # bug fixes
use version 0.70;

use Test::Builder;
@Test::MinimumVersion::EXPORT = qw(
  minimum_version_ok
  all_minimum_version_ok
  all_minimum_version_from_metayml_ok
);

sub import {
  my($self) = shift;
  my $pack = caller;

  my $Test = Test::Builder->new;

  $Test->exported_to($pack);
  $Test->plan(@_);

  $self->export_to_level(1, $self, @Test::MinimumVersion::EXPORT);
}

sub _objectify_version {
  my ($version) = @_;
  $version = eval { $version->isa('version') } 
           ? $version
           : version->new($version);
}


sub minimum_version_ok {
  my ($file, $version) = @_;

  my $Test = Test::Builder->new;

  $version = _objectify_version($version);

  my $pmv = Perl::MinimumVersion->new($file);

  my $explicit_minimum = $pmv->minimum_explicit_version || 0;
  my $minimum = $pmv->minimum_syntax_version($explicit_minimum) || 0;

  my $is_syntax = 1
    if $minimum and $minimum > $explicit_minimum;

  $minimum = $explicit_minimum
    if $explicit_minimum and $explicit_minimum > $minimum;

  my %min = $pmv->version_markers;

  if ($minimum <= $version) {
    $Test->ok(1, $file);
  } else {
    $Test->ok(0, $file);
    $Test->diag(
      "$file requires $minimum "
      . ($is_syntax ? 'due to syntax' : 'due to explicit requirement')
    );

    if ($is_syntax and my $markers = $min{ $minimum }) {
      $Test->diag("version markers for $minimum:");
      $Test->diag("- $_ ") for @$markers;
    }
  }
}


sub all_minimum_version_ok {
  my ($version, $arg) = @_;
  $arg ||= {};
  $arg->{paths} ||= [ qw(lib t xt/smoke), glob ("*.pm"), glob ("*.PL") ];

  my $Test = Test::Builder->new;

  $version = _objectify_version($version);

  my @perl_files;
  for my $path (@{ $arg->{paths} }) {
    if (-f $path and -s $path) {
      push @perl_files, $path;
    } elsif (-d $path) {
      push @perl_files, File::Find::Rule->perl_file->in($path);
    }
  }

  unless ($Test->has_plan or $arg->{no_plan}) {
    $Test->plan(tests => scalar @perl_files);
  }

  minimum_version_ok($_, $version) for @perl_files;
}


sub all_minimum_version_from_metayml_ok {
  my ($arg) = @_;
  $arg ||= {};

  my $Test = Test::Builder->new;

  $Test->plan(skip_all => "META.yml could not be found")
    unless -f 'META.yml' and -r _;

  my $documents = YAML::Tiny->read('META.yml');

  $Test->plan(skip_all => "no minimum perl version could be determined")
    unless my $version = $documents->[0]->{requires}{perl};

  all_minimum_version_ok($version, $arg);
}

1;

__END__
=pod

=head1 NAME

Test::MinimumVersion - does your code require newer perl than you think?

=head1 VERSION

version 0.101080

=head1 SYNOPSIS

Example F<minimum-perl.t>:

  #!perl
  use Test::MinimumVersion;
  all_minimum_version_ok('5.008');

=head1 FUNCTIONS

=head2 minimum_version_ok

  minimum_version_ok($file, $version);

This test passes if the given file does not seem to require any version of perl
newer than C<$version>, which may be given as a version string or a version
object.

=head2 all_minimum_version_ok

  all_minimum_version_ok($version, \%arg);

Given either a version string or a L<version> object, this routine produces a
test plan (if there is no plan) and tests each relevant file with
C<minimum_version_ok>.

Relevant files are found by L<File::Find::Rule::Perl>.

C<\%arg> is optional.  Valid arguments are:

  paths   - in what paths to look for files; defaults to (t, lib, xt/smoke,
            and any .pm or .PL files in the current working directory)
            if it contains files, they will be checked
  no_plan - do not plan the tests about to be run

=head2 all_minimum_version_from_metayml_ok

  all_minimum_version_from_metayml_ok(\%arg);

This routine checks F<META.yml> for an entry in F<requires> for F<perl>.  If no
META.yml file or no perl version is found, all tests are skipped.  If a version
is found, the test proceeds as if C<all_minimum_version_ok> had been called
with that version.

=head1 AUTHOR

  Ricardo Signes

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


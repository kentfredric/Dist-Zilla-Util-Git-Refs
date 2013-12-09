use strict;
use warnings;

package Dist::Zilla::Util::Git::Refs;

# ABSTRACT: Work with refs

use Moose;
use MooseX::LazyRequire;

=head1 SYNOPSIS

After doing lots of work with Git::Wrapper, I found there's quite a few ways to
work with refs, and those ways aren't exactly all equal, or supported on all versions of git.

This abstracts it so things can just use them.

    my $refs = Dist::Zilla::Util::Git::Refs->new();

    $refs->refs(); # A ::Ref object for each entry from `git ls-remote .`

    my ( @results ) = $refs->get_ref('refs/**'); # the same thing

    my ( @results ) = $refs->get_ref('refs/heads/**'); # all branches

    my ( @results ) = $refs->get_ref('refs/tags/**'); # all tags

    my ( @results ) = $refs->get_ref('refs/remotes/**'); # all remote branches

Note: You probably shouldn't use this module directly, and should instead use one of the C<::Util::Git> family.

=cut

has git => ( is => ro =>, isa => Object =>, lazy_build => 1 );

sub _build_git {
  my ($self) = @_;
  require Dist::Zilla::Util::Git::Wrapper;
  return Dist::Zilla::Util::Git::Wrapper->new( zilla => $self->zilla );
}

has zilla => ( is => ro =>, isa => Object =>, lazy_required => 1 );

sub _for_each_ref {
  my ( $self, $refspec, $callback ) = @_;

  my $git_dir = $self->git->dir;
  for my $line ( $self->git->ls_remote( $git_dir, $refspec ) ) {
    if ( $line =~ qr{ \A ([^\t]+) \t ( .+ ) \z }msx ) {
      $callback->( $1, $2 );
      next;
    }
    require Carp;
    Carp::confess( 'Regexp failed to parse a line from `git ls-remote` :' . $line );
  }
  return;
}

sub refs {
  my ($self) = @_;
  return $self->get_ref('refs/**');
}

sub get_ref {
  my ( $self, $refspec ) = @_;
  my @out;
  $self->_for_each_ref(
    $refspec => sub {
      my ( $sha1, $refname ) = @_;
      push @out, $self->_mk_ref( $sha1, $refname );
    }
  );
  return @out;
}

sub _mk_ref {
  my ( $self, $sha1, $name ) = @_;
  require Dist::Zilla::Util::Git::Refs::Ref;
  return Dist::Zilla::Util::Git::Refs::Ref->new(
    git  => $self->git,
    name => $name,
  );
}
__PACKAGE__->meta->make_immutable;
no Moose;

1;

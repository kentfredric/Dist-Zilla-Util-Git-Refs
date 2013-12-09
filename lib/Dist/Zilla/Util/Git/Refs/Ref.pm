use strict;
use warnings;
use utf8;

package Dist::Zilla::Util::Git::Refs::Ref;

# ABSTRACT: An Abstract REF node

use Moose;

=attr C<name>

=attr C<git>

=cut

has name => ( isa => 'Str',    required => 1, is => ro => );
has git  => ( isa => 'Object', required => 1, is => ro => );

=method C<refname>

Return the fully qualified ref name for this object.

=cut

sub refname {
  my ($self) = @_;
  return $self->name;
}

=method C<sha1>

Return the C<SHA1> resolving for C<refname>

=cut

sub sha1 {
  my ($self)    = @_;
  my ($refname) = $self->refname;
  my (@sha1s)   = $self->git->rev_parse($refname);
  if ( scalar @sha1s > 1 ) {
    require Carp;
    return Carp::confess( q[Fatal: rev-parse ] . $refname . q[ returned multiple values] );
  }
  return shift @sha1s;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;


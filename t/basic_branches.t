
use strict;
use warnings;

use Test::More;

use Path::Tiny qw(path);

my $tempdir = Path::Tiny->tempdir;
my $repo    = $tempdir->child('git-repo');
my $home    = $tempdir->child('homedir');

local $ENV{HOME}                = $home->absolute->stringify;
local $ENV{GIT_AUTHOR_NAME}     = 'A. U. Thor';
local $ENV{GIT_AUTHOR_EMAIL}    = 'author@example.org';
local $ENV{GIT_COMMITTER_NAME}  = 'A. U. Thor';
local $ENV{GIT_COMMITTER_EMAIL} = 'author@example.org';

$repo->mkpath;
my $file = $repo->child('testfile');

use Dist::Zilla::Util::Git::Wrapper;
use Git::Wrapper;
use Test::Fatal qw(exception);

my $git = Git::Wrapper->new( $tempdir->child('git-repo') );
my $wrapper = Dist::Zilla::Util::Git::Wrapper->new( git => $git );

sub report_ctx {
  my (@lines) = @_;
  note explain \@lines;
}

my $tip;

my $excp = exception {
  $wrapper->init();
  $file->touch;
  $wrapper->add($file);
  $wrapper->commit( '-m', 'Test Commit' );
  $wrapper->checkout( '-b', 'master_2' );
  $file->spew('New Content');
  $wrapper->add($file);
  $wrapper->commit( '-m', 'Test Commit 2' );
  $wrapper->checkout( '-b', 'master_3' );

  ( $tip, ) = $wrapper->rev_parse('HEAD');
};
is( $excp, undef, 'Git::Wrapper methods executed without failure' ) or diag $excp;

use Dist::Zilla::Util::Git::Refs;
my $branch_finder = Dist::Zilla::Util::Git::Refs->new( git => $wrapper );

is( scalar $branch_finder->get_ref('refs/heads/**'), 3, '3 Branches found' );
my $branches = {};
for my $branch ( $branch_finder->get_ref('refs/heads/**') ) {
  $branches->{ $branch->name } = $branch;
}
ok( exists $branches->{'refs/heads/master'},   'master branch found' );
ok( exists $branches->{'refs/heads/master_2'}, 'master_2 branch found' );
ok( exists $branches->{'refs/heads/master_3'}, 'master_3 branch found' );
is(
  $branches->{'refs/heads/master_2'}->sha1,
  $branches->{'refs/heads/master_3'}->sha1,
  'master_2 and master_3 have the same sha1'
);

done_testing;

